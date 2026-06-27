import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'role_selection_screen.dart';

import '../api_service.dart';
import '../attendance_service.dart';

class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // UI State
  String _statusText = 'Ready to scan';
  String _subStatusText = 'Please stand within the frame';
  Color _statusColor = Colors.white;
  IconData _statusIcon = Icons.face;

  // Logic State
  String? _lastTeacherId;
  DateTime _lastTeacherMarked =
  DateTime.fromMillisecondsSinceEpoch(0);
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final chosen = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        chosen,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      _updateStatus(
        'Camera Error',
        e.toString(),
        Colors.red,
        Icons.error,
      );
    }
  }

  void _updateStatus(
      String title,
      String subtitle,
      Color color,
      IconData icon,
      ) {
    if (!mounted) return;
    setState(() {
      _statusText = title;
      _subStatusText = subtitle;
      _statusColor = color;
      _statusIcon = icon;
    });
  }

  void _resetStatusDelayed() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isProcessing) {
        _updateStatus(
          'Ready to scan',
          'Please stand within the frame',
          Colors.white,
          Icons.face,
        );
      }
    });
  }

  Future<File> _fixImageOrientation(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;

      final fixed = img.bakeOrientation(decoded);
      final ext = p.extension(file.path).toLowerCase();
      final newPath = file.path.replaceFirst(ext, '_fixed$ext');

      final encoded = ext == '.png'
          ? img.encodePng(fixed)
          : img.encodeJpg(fixed, quality: 85);

      final newFile = File(newPath);
      await newFile.writeAsBytes(encoded, flush: true);
      return newFile;
    } catch (_) {
      return file;
    }
  }

  Future<void> _takePhotoAndIdentify() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    _updateStatus(
      'Processing...',
      'Analyzing face...',
      Colors.blue,
      Icons.hourglass_top,
    );

    try {
      final pic = await _cameraController!.takePicture();
      final rawFile = File(pic.path);
      final processedFile = await _fixImageOrientation(rawFile);

      final result =
      await ApiService.identifyTeacher(processedFile);

      if (!mounted) return;

      if (result['status'] == 'OK') {
        await _handleSuccess(
            result['teacherId'], result['name']);
      } else if (result['status'] == 'NO_FACE') {
        _updateStatus(
          'No Face Detected',
          'Please look at the camera',
          Colors.orange,
          Icons.face_retouching_off,
        );
        _resetStatusDelayed();
      } else if (result['status'] == 'NO_MATCH') {
        _updateStatus(
          'Access Denied',
          'Face not recognized',
          Colors.red,
          Icons.block,
        );
        _resetStatusDelayed();
      } else {
        _updateStatus(
          'Error',
          result['status'] ?? 'Unknown error',
          Colors.red,
          Icons.error_outline,
        );
        _resetStatusDelayed();
      }
    } catch (e) {
      _updateStatus(
        'System Error',
        e.toString(),
        Colors.red,
        Icons.error,
      );
      _resetStatusDelayed();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSuccess(
      String teacherId, String name) async {
    final nowTime = DateTime.now();

    // Local debounce to prevent rapid re-scan
    if (_lastTeacherId == teacherId &&
        nowTime.difference(_lastTeacherMarked).inMinutes < 1) {
      _updateStatus(
        'Already Scanned',
        'Please wait before scanning again',
        Colors.amber,
        Icons.history,
      );
      _resetStatusDelayed();
      return;
    }

    // Backend-driven check
    final hasOpenSession =
    await AttendanceService.getOpenSession(teacherId);

    if (!hasOpenSession) {
      // ENTRY
      await AttendanceService.createEntrySession(
        teacherId: teacherId,
        teacherName: name,
        mode: 'FACE',
        nowTime: nowTime,
      );

      _playSuccessFeedback(
          name, 'Entry Marked', nowTime);
    } else {
      // EXIT CONFIRMATION
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Exit'),
          content: Text(
            'Hi $name, do you want to mark your Exit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Exit'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await AttendanceService.closeSession(
          teacherId: teacherId,
          nowTime: nowTime,
        );

        _playSuccessFeedback(
            name, 'Exit Marked', nowTime);
      } else {
        _updateStatus(
          'Cancelled',
          'Exit not marked',
          Colors.grey,
          Icons.cancel,
        );
        _resetStatusDelayed();
      }
    }

    _lastTeacherId = teacherId;
    _lastTeacherMarked = nowTime;
  }


  void _playSuccessFeedback(
      String name, String action, DateTime time) {
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    _updateStatus(
      'Success: $name',
      '$action at $timeStr',
      Colors.green,
      Icons.check_circle,
    );
    _resetStatusDelayed();
  }

  Future<void> _startCountdown() async {
    if (_countdownTimer != null || _isProcessing) return;
    setState(() => _countdown = 3);

    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          setState(() {
            _countdown--;
            if (_countdown == 0) {
              t.cancel();
              _countdownTimer = null;
              _takePhotoAndIdentify();
            }
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera
          if (_isCameraInitialized && _cameraController != null)
            Center(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator()),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Face Frame
          Center(
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _statusColor == Colors.white
                      ? Colors.white.withOpacity(0.5)
                      : _statusColor,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _countdown > 0
                  ? Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 80,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : null,
            ),
          ),

          // HEADER — STANDARD BACK BUTTON
          Positioned(
            top: 33,
            left: 8,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const RoleSelectionScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATTENDANCE KIOSK',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Little Scholars',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Status Card + Button (unchanged)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                AnimatedContainer(
                  duration:
                  const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: _statusColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        height: 45,
                        child: _statusText == 'Ready to scan'
                            ? Image.asset(
                          'assets/face_scan.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(
                            Icons.face_retouching_natural,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                        )
                            : Icon(_statusIcon,
                            size: 40,
                            color: _statusColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _statusColor ==
                                    Colors.white
                                    ? Colors.black87
                                    : _statusColor,
                              ),
                            ),
                            Text(
                              _subStatusText,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54),
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                    _isProcessing ? null : _startCountdown,
                    child: _isProcessing
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      'TAP TO SCAN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
