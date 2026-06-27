// lib/screens/teachers_directory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for direct DB access
import '../api_service.dart';
import 'attendance_history_screen.dart';

class TeachersDirectoryScreen extends StatefulWidget {
  const TeachersDirectoryScreen({super.key});

  @override
  State<TeachersDirectoryScreen> createState() => _TeachersDirectoryScreenState();
}

class _TeachersDirectoryScreenState extends State<TeachersDirectoryScreen> {
  List<Map<String, dynamic>> _teachers = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  // We still fetch the LIST of teachers from backend (for profiles/names)
  Future<void> _loadTeachers() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.listTeachers();
      setState(() => _teachers = List<Map<String, dynamic>>.from(list));
    } catch (e) {
      debugPrint('Load teachers error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load directory: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteTeacher(String teacherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Delete Teacher', style: TextStyle(color: Colors.white)),
        content: Text('Delete $teacherId? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteTeacher(teacherId);
      await _loadTeachers();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete error: $e')));
    }
  }

  void _openWhatsapp(String phone) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone number not available')));
      return;
    }

    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    // Add India country code if missing
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final url = 'https://wa.me/$cleanPhone';

    try {
      await ApiService.launchExternalUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
    }
  }


  void _gotoHistory(Map<String, dynamic> teacher) {
    final teacherId = teacher['teacherId']?.toString() ?? '';
    final teacherName = teacher['name']?.toString() ?? '';
    final profileUrl = _resolveProfileUrl(teacher);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceHistoryScreen(
            teacherId: teacherId,
            teacherName: teacherName,
            profileUrl: profileUrl
        ),
      ),
    );
  }

  // --- UPDATED: Direct Firestore Export ---
  Future<void> _exportAttendanceText(String teacherId, String teacherName, String phone) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating report...')));

      // Query 'attendanceSessions' directly as per your Service schema
      // Note: You might need a Firestore Composite Index for (teacherId ASC, checkIn DESC)
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('attendanceSessions')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('checkIn', descending: true)
          .get();

      final buffer = StringBuffer();
      buffer.writeln('Attendance Report for: $teacherName ($teacherId)');
      buffer.writeln('Phone: $phone');
      buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
      buffer.writeln('--------------------------------------------------');

      if (snapshot.docs.isEmpty) {
        buffer.writeln('No attendance records found.');
      }

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle Timestamps
        final DateTime? checkIn = (data['checkIn'] as Timestamp?)?.toDate();
        final DateTime? checkOut = (data['checkOut'] as Timestamp?)?.toDate();

        final dateStr = checkIn != null
            ? "${checkIn.day}/${checkIn.month}/${checkIn.year}"
            : (data['date'] ?? "Unknown Date");

        final inTime = checkIn != null
            ? "${checkIn.hour.toString().padLeft(2,'0')}:${checkIn.minute.toString().padLeft(2,'0')}"
            : "--:--";

        final outTime = checkOut != null
            ? "${checkOut.hour.toString().padLeft(2,'0')}:${checkOut.minute.toString().padLeft(2,'0')}"
            : "Active (Still Inside)";

        buffer.writeln('$dateStr | In: $inTime | Out: $outTime');
      }

      buffer.writeln('--------------------------------------------------');

      await Clipboard.setData(ClipboardData(text: buffer.toString()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied to clipboard!')));

    } catch (e) {
      debugPrint("Export Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  String _resolveProfileUrl(Map<String, dynamic> t) {
    const baseUrl = ApiService.baseUrl;

    final candidates = [
      'profileUrl',
      'profilePhoto',
      'profile_photo',
      'profilePhotoPath',
    ];

    for (final k in candidates) {
      final v = t[k];
      if (v is String && v.trim().isNotEmpty) {
        // If backend already sent full URL
        if (v.startsWith('http://') || v.startsWith('https://')) {
          return v;
        }

        // Relative path → convert to absolute
        final normalized = v.startsWith('/') ? v : '/$v';
        return '$baseUrl$normalized';
      }
    }
    return '';
  }


  // --- UI Components (Glassmorphism) ---

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          hintText: 'Search by name or ID',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final id = teacher['teacherId']?.toString() ?? 'N/A';
    final name = teacher['name']?.toString() ?? 'Unknown';
    final phone = teacher['phone']?.toString() ?? '';
    final profile = _resolveProfileUrl(teacher);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white10,
                    image: profile.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(profile),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        debugPrint('Profile image failed to load: $profile');
                      },
                    )
                        : null,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: profile.isEmpty
                      ? Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)))
                      : null,
                ),

                const SizedBox(width: 16),

                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(id, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.phone_iphone, size: 12, color: Colors.white54),
                            const SizedBox(width: 2),
                            Text(phone, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        cardColor: const Color(0xFF2C2C2C),
                        popupMenuTheme: const PopupMenuThemeData(textStyle: TextStyle(color: Colors.white)),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        onSelected: (v) {
                          if (v == 'delete') _deleteTeacher(id);
                          if (v == 'history') _gotoHistory(teacher);
                          if (v == 'export') _exportAttendanceText(id, name, phone);
                          if (v == 'whatsapp') _openWhatsapp(phone);
                          if (v == 'copy') {
                            Clipboard.setData(ClipboardData(text: phone));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone copied')));
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'history', child: Row(children: [Icon(Icons.history, color: Colors.white70, size: 18), SizedBox(width: 8), Text('History')])),
                          const PopupMenuItem(value: 'export', child: Row(children: [Icon(Icons.copy, color: Colors.white70, size: 18), SizedBox(width: 8), Text('Copy Report')])),
                          const PopupMenuItem(value: 'whatsapp', child: Row(children: [Icon(Icons.chat_bubble_outline, color: Colors.greenAccent, size: 18), SizedBox(width: 8), Text('WhatsApp', style: TextStyle(color: Colors.greenAccent))])),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.redAccent))])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _teachers.where((t) {
      final nm = (t['name'] ?? '').toString().toLowerCase();
      final id = (t['teacherId'] ?? '').toString().toLowerCase();
      final q = _query.trim().toLowerCase();
      return q.isEmpty || nm.contains(q) || id.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent, // Parent gradient shows through
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: IconButton(
                    onPressed: _loadTeachers,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.orangeAccent),
                    tooltip: 'Refresh',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ScrollConfiguration(
                behavior: BouncingScrollBehavior(),
                child: _loading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                )
                    : filtered.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_outlined,
                          size: 48, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No teachers found',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) =>
                      _buildTeacherCard(filtered[idx]),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class BouncingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child; // removes glow
  }
}

