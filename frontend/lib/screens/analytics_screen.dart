import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  /* ==========================================
     LOGIC & STATE (UNCHANGED)
     ========================================== */
  bool _loading = true;
  List<_TeacherAnalytics> _data = [];
  String _sortBy = 'attendance';

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> _dateKeysInRange(DateTime start, DateTime end) {
    final List<String> keys = [];
    final days = end.difference(start).inDays + 1;
    for (int i = 0; i < days; i++) {
      keys.add(_dateKey(start.add(Duration(days: i))));
    }
    return keys;
  }

  String _formatMinutes(int? minutes) {
    if (minutes == null) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final suffix = h >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  Color _attendanceColor(double percent) {
    if (percent >= 90) return Colors.greenAccent;
    if (percent >= 75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent,
            onPrimary: Colors.black,
            surface: Colors.grey,
          ),
        ),
        child: child!,
      ),
    );

    if (range != null) {
      setState(() => _dateRange = range);
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);

    try {
      final start = DateTime(
        _dateRange.start.year,
        _dateRange.start.month,
        _dateRange.start.day,
      );
      final end = DateTime(
        _dateRange.end.year,
        _dateRange.end.month,
        _dateRange.end.day,
      );

      final dateKeys = _dateKeysInRange(start, end);
      final List<Map<String, dynamic>> records = [];

      for (int i = 0; i < dateKeys.length; i += 10) {
        final chunk = dateKeys.skip(i).take(10).toList();
        if (chunk.isEmpty) continue;
        final snap = await FirebaseFirestore.instance
            .collection('attendanceSessions')
            .where('date', whereIn: chunk)
            .get();
        records.addAll(snap.docs.map((d) => d.data()));
      }

      final Map<String, _TempTeacherAgg> agg = {};

      for (final r in records) {
        final id = r['teacherId'].toString();
        final name = r['teacherName'] ?? 'Unknown';
        final date = r['date'];

        agg.putIfAbsent(id, () => _TempTeacherAgg(name));
        agg[id]!.presentDays.add(date);

        if (r['checkIn'] != null) {
          final checkIn = (r['checkIn'] as Timestamp).toDate();
          final minutes = checkIn.hour * 60 + checkIn.minute;
          agg[id]!.entryMinutesSum += minutes;

          if (minutes > 555) agg[id]!.lateDays.add(date);
        }
      }

      _data = agg.values.map((t) {
        final present = t.presentDays.length;
        final total = dateKeys.length;
        final percent = total == 0 ? 0.0 : (present / total) * 100.0;

        return _TeacherAnalytics(
          name: t.teacherName,
          present: present,
          absent: (total - present).clamp(0, total),
          attendancePercent: percent,
          lateCount: t.lateDays.length,
          avgEntryMinutes:
          present == 0 ? null : (t.entryMinutesSum ~/ present),
        );
      }).toList();

      _applySorting();
    } catch (e) {
      debugPrint("Error loading analytics: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySorting() {
    if (_sortBy == 'attendance') {
      _data.sort(
              (a, b) => b.attendancePercent.compareTo(a.attendancePercent));
    } else if (_sortBy == 'late') {
      _data.sort((a, b) => b.lateCount.compareTo(a.lateCount));
    } else {
      _data.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /* ==========================================
     UI SECTION
     ========================================== */

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Header
        _GlassHeader(
          range: _dateRange,
          onPick: _pickDateRange,
          sortBy: _sortBy,
          onSort: (v) => setState(() {
            _sortBy = v;
            _applySorting();
          }),
        ),

        // 2. Main List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : _data.isEmpty
              ? const Center(
              child: Text("No data found", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
            // ------------------------------------------
            // ADDED BOUNCING PHYSICS HERE
            // ------------------------------------------
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _data.length,
            itemBuilder: (_, i) => _GlassAnalyticsCard(
              data: _data[i],
              color: _attendanceColor(_data[i].attendancePercent),
              avgEntry: _formatMinutes(_data[i].avgEntryMinutes),
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================
   UI COMPONENTS
   ========================= */

class _GlassHeader extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onPick;
  final String sortBy;
  final ValueChanged<String> onSort;

  const _GlassHeader({
    required this.range,
    required this.onPick,
    required this.sortBy,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Date Range',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Text(
                      '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_calendar,
                        color: Colors.cyanAccent, size: 16),
                  ],
                ),
              ),
            ],
          ),

          // Sort Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortBy,
                icon: const Icon(Icons.sort, color: Colors.white70, size: 18),
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'attendance', child: Text('Attendance')),
                  DropdownMenuItem(value: 'late', child: Text('Late Count')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                ],
                onChanged: (v) => onSort(v!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassAnalyticsCard extends StatelessWidget {
  final _TeacherAnalytics data;
  final Color color;
  final String avgEntry;

  const _GlassAnalyticsCard({
    required this.data,
    required this.color,
    required this.avgEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 1. Top Section: Name & Percent
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            'Avg Entry: $avgEntry',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Percent Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${data.attendancePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (data.attendancePercent / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                color: color,
                minHeight: 4,
              ),
            ),
          ),

          // 3. Bottom Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Present',
                  value: data.present.toString(),
                  color: Colors.greenAccent,
                ),
                _VerticalDivider(),
                _StatItem(
                  icon: Icons.cancel_outlined,
                  label: 'Absent',
                  value: data.absent.toString(),
                  color: Colors.redAccent,
                ),
                _VerticalDivider(),
                _StatItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Late',
                  value: data.lateCount.toString(),
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white12,
    );
  }
}

// ==========================================
// MODELS (UNCHANGED)
// ==========================================

class _TempTeacherAgg {
  final String teacherName;
  final Set<String> presentDays = {};
  final Set<String> lateDays = {};
  int entryMinutesSum = 0;

  _TempTeacherAgg(this.teacherName);
}

class _TeacherAnalytics {
  final String name;
  final int present;
  final int absent;
  final double attendancePercent;
  final int lateCount;
  final int? avgEntryMinutes;

  _TeacherAnalytics({
    required this.name,
    required this.present,
    required this.absent,
    required this.attendancePercent,
    required this.lateCount,
    required this.avgEntryMinutes,
  });
}