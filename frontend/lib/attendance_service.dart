// attendance_service.dart
// Kiosk version — backend-driven, NO Firebase

import '../api_service.dart';

class AttendanceService {
  /// Check if the teacher currently has an open session
  /// Calls backend instead of Firestore
  static Future<bool> getOpenSession(String teacherId) async {
    try {
      return await ApiService.hasOpenSession(teacherId);
    } catch (_) {
      return false;
    }
  }

  /// ENTRY — backend writes Firestore + sends notification
  static Future<void> createEntrySession({
    required String teacherId,
    required String teacherName,
    required String mode,
    required DateTime nowTime, // kept for call-site compatibility
  }) async {
    await ApiService.markEntry(
      teacherId: teacherId,
      teacherName: teacherName,
      mode: mode,
    );
  }

  /// EXIT — backend updates Firestore + sends notification
  static Future<void> closeSession({
    required String teacherId,
    required DateTime nowTime, // kept for call-site compatibility
  }) async {
    await ApiService.markExit(
      teacherId: teacherId,
    );
  }
}
