// lib/screens/live_status_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';
import 'attendance_history_screen.dart';

class LiveStatusScreen extends StatefulWidget {
  const LiveStatusScreen({super.key});

  @override
  State<LiveStatusScreen> createState() => _LiveStatusScreenState();
}

class _LiveStatusScreenState extends State<LiveStatusScreen> {
  final String _query = '';
  final String _activeFilter = 'All';

  bool _loadingTeachers = true;

  final Map<String, Map<String, dynamic>> _teachersById = {};

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  // ---------- DATA ----------

  Future<void> _loadTeachers() async {
    try {
      final list = await ApiService.listTeachers();
      for (final t in list) {
        final id = t['teacherId']?.toString();
        if (id != null) {
          _teachersById[id] = Map<String, dynamic>.from(t);
        }
      }
    } catch (e) {
      debugPrint('Failed to load teachers: $e');
    } finally {
      if (mounted) setState(() => _loadingTeachers = false);
    }
  }

  Stream<QuerySnapshot> _getTodayStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('attendanceSessions')
        .where('checkIn',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('checkIn', descending: true)
        .snapshots();
  }

  // ---------- HELPERS ----------

  String _resolveProfileUrl(Map<String, dynamic> t) {
    const baseUrl = ApiService.baseUrl;
    const keys = [
      'profileUrl',
      'profilePhoto',
      'profile_photo',
      'profilePhotoPath'
    ];

    for (final k in keys) {
      final v = t[k];
      if (v is String && v.trim().isNotEmpty) {
        if (v.startsWith('http')) return v;
        return '$baseUrl${v.startsWith('/') ? v : '/$v'}';
      }
    }
    return '';
  }

  String _formatTime(dynamic checkIn) {
    if (checkIn == null) return '--:--';
    final d = checkIn is Timestamp
        ? checkIn.toDate()
        : DateTime.tryParse(checkIn.toString()) ?? DateTime.now();
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _durationFrom(dynamic checkIn, dynamic checkOut) {
    if (checkIn == null) return '--';

    final start = checkIn is Timestamp
        ? checkIn.toDate()
        : DateTime.tryParse(checkIn.toString()) ?? DateTime.now();

    final end = checkOut != null
        ? (checkOut is Timestamp
        ? checkOut.toDate()
        : DateTime.tryParse(checkOut.toString()) ?? DateTime.now())
        : DateTime.now();

    final diff = end.difference(start);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Future<void> _openWhatsApp(String phone) async {
    var clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDetails(String teacherId, String teacherName) {
    final teacher = _teachersById[teacherId];
    final profile = teacher != null ? _resolveProfileUrl(teacher) : '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceHistoryScreen(
          teacherId: teacherId,
          teacherName: teacherName,
          profileUrl: profile,
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    if (_loadingTeachers) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getTodayStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final raw =
        docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final filtered = raw.where((s) {
          final name = (s['teacherName'] ?? '').toString().toLowerCase();
          final q = _query.toLowerCase();
          final isInside = s['checkOut'] == null;

          return (q.isEmpty || name.contains(q)) &&
              (_activeFilter == 'All' ||
                  (_activeFilter == 'Inside' && isInside) ||
                  (_activeFilter == 'Outside' && !isInside));
        }).toList();

        if (filtered.isEmpty &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent));
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No attendance records for today',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: Colors.orangeAccent,
          child: ScrollConfiguration(
            behavior: BouncingScrollBehavior(),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final s = filtered[idx];
                final teacherId = s['teacherId'];
                final teacherName = s['teacherName'] ?? 'Unknown';
                final phone = s['phone'] ?? '';
                final isInside = s['checkOut'] == null;

                final teacher = _teachersById[teacherId];
                final profile =
                teacher != null ? _resolveProfileUrl(teacher) : '';

                return InkWell(
                  onTap: () => _openDetails(teacherId, teacherName),
                  child: _buildLiveCard(
                    teacherName,
                    phone,
                    profile,
                    isInside,
                    s,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveCard(
      String teacherName,
      String phone,
      String profile,
      bool isInside,
      Map<String, dynamic> s,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInside
              ? Colors.greenAccent.withOpacity(0.15)
              : Colors.redAccent.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white10,
              border: Border.all(color: Colors.white12),
              image: profile.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(profile),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: profile.isEmpty
                ? Center(
              child: Text(
                teacherName.isNotEmpty
                    ? teacherName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(_formatTime(s['checkIn']),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer,
                        size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(_durationFrom(s['checkIn'], s['checkOut']),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Status + WhatsApp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInside
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isInside ? Colors.green : Colors.red,
                      width: 1.5),
                ),
                child: Text(
                  isInside ? 'IN' : 'OUT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isInside
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (phone.isNotEmpty)
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chat,
                      color: Colors.greenAccent, size: 24),
                  onPressed: () => _openWhatsApp(phone),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- SCROLL BEHAVIOR ----------

class BouncingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
