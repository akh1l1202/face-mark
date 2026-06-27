// lib/screens/attendance_history_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String profileUrl;

  const AttendanceHistoryScreen({
    required this.teacherId,
    required this.teacherName,
    this.profileUrl = '',
    super.key
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      // Direct Firestore Query
      final snapshot = await FirebaseFirestore.instance
          .collection('attendanceSessions')
          .where('teacherId', isEqualTo: widget.teacherId)
          .orderBy('checkIn', descending: true)
          .get();

      final fetchedLogs = snapshot.docs.map((doc) {
        final data = doc.data();

        // Parse Timestamps
        final DateTime? inTime = (data['checkIn'] as Timestamp?)?.toDate();
        final DateTime? outTime = (data['checkOut'] as Timestamp?)?.toDate();
        final int? duration = data['durationMinutes'] as int?;
        String durationStr = "--";
        if (duration != null) {
          final int hours = duration ~/ 60;   // Integer division for hours
          final int minutes = duration % 60;  // Remainder for minutes
          durationStr = "${hours}h ${minutes}m";
        }

        return {
          'dateObj': inTime, // stored for sorting if needed
          'dateStr': inTime != null
              ? "${inTime.day}/${inTime.month}/${inTime.year}"
              : "Unknown Date",
          'checkIn': inTime != null
              ? "${inTime.hour.toString().padLeft(2,'0')}:${inTime.minute.toString().padLeft(2,'0')}"
              : "--:--",
          'checkOut': outTime != null
              ? "${outTime.hour.toString().padLeft(2,'0')}:${outTime.minute.toString().padLeft(2,'0')}"
              : "Active",
          'duration': durationStr,
          'status': (outTime == null) ? 'Inside' : 'Completed'
        };
      }).toList();

      setState(() => _logs = fetchedLogs);
    } catch (e) {
      debugPrint('Load logs error: $e');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyTextExport() async {
    final buffer = StringBuffer();
    buffer.writeln('Attendance Report for: ${widget.teacherName} (${widget.teacherId})');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('--------------------------------------------------');

    for (final log in _logs) {
      buffer.writeln('${log['dateStr']} | In: ${log['checkIn']} | Out: ${log['checkOut']} | Dur: ${log['duration']}');
    }

    buffer.writeln('--------------------------------------------------');
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied to clipboard')));
  }

  // --- UI Components ---

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: widget.profileUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(widget.profileUrl), fit: BoxFit.cover)
                      : null,
                  color: Colors.white10,
                ),
                child: widget.profileUrl.isEmpty
                    ? Center(child: Text(widget.teacherName.isNotEmpty ? widget.teacherName[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.teacherName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("ID: ${widget.teacherId}", style: const TextStyle(color: Colors.orangeAccent, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final isInside = log['status'] == 'Inside';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isInside ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isInside ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.08)
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
            log['dateStr'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.login, size: 14, color: Colors.greenAccent.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(log['checkIn'], style: const TextStyle(color: Colors.white70, fontSize: 12)),

              const SizedBox(width: 16),

              Icon(Icons.logout, size: 14, color: Colors.redAccent.withOpacity(0.8)),
              const SizedBox(width: 4),
              Text(log['checkOut'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(log['duration'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if(isInside)
              const Text("LIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.black],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Attendance History', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              onPressed: _logs.isEmpty ? null : _copyTextExport,
              icon: const Icon(Icons.copy, color: Colors.white70),
              tooltip: "Copy Report",
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGlassHeader(),
              const SizedBox(height: 20),

              if (_logs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text("No attendance records found.", style: TextStyle(color: Colors.white38)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _logs.length,
                    itemBuilder: (context, idx) => _buildLogCard(_logs[idx]),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}