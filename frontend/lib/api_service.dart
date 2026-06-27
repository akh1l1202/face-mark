// lib/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  // TODO: change this to your deployed backend URL once hosted
  static const String baseUrl = 'http://x.local:8000';

  /// Identify a teacher by sending a face image to your backend
  static Future<Map<String, dynamic>> identifyTeacher(File imageFile) async {
    final uri = Uri.parse('$baseUrl/identify');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Identify failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Register a teacher. Accepts a list of images; for your current UI you will
  /// typically pass a single image in the list (profile photo).
  static Future<Map<String, dynamic>> registerTeacher({
    required String teacherId,
    required String name,
    required List<File> images,
    String? phone,
    int profileIndex = 0, // NEW default
  }) async {
    final uri = Uri.parse('$baseUrl/register');
    final request = http.MultipartRequest('POST', uri);

    request.fields['teacherId'] = teacherId;
    request.fields['name'] = name;
    request.fields['profileIndex'] = profileIndex.toString();

    if (phone != null) request.fields['phone'] = phone;

    for (final img in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', img.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Register failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// List all teachers. Expects backend to reply: { "teachers": [ { ... }, ... ] }
  static Future<List<Map<String, dynamic>>> listTeachers() async {
    final uri = Uri.parse('$baseUrl/teachers');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to list teachers: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // safe-cast to list of maps
    final rawList = data['teachers'] as List<dynamic>;
    return rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Delete a teacher
  static Future<void> deleteTeacher(String teacherId) async {
    final uri = Uri.parse('$baseUrl/teacher/$teacherId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete: ${res.body}');
    }
  }


  static Future<List<Map<String, dynamic>>> getAttendanceLogsForTeacher(String teacherId) async {
    final uri = Uri.parse('$baseUrl/attendance/$teacherId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch attendance logs: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = json['logs'] as List<dynamic>? ?? <dynamic>[];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Simple wrapper to open external URLs (WhatsApp link etc.)
  /// Uses url_launcher under the hood.
  static Future<void> launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw Exception('Invalid url: $url');

    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch URL: $url');
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not launch URL: $url');
    }
  }

  static Future<bool> hasOpenSession(String teacherId) async {
    final uri = Uri.parse('$baseUrl/attendance/open-session?teacherId=$teacherId');
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to check open session: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['hasOpenSession'] == true;
  }

  static Future<void> markEntry({
    required String teacherId,
    required String teacherName,
    required String mode,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance/entry');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'teacherId': teacherId,
        'teacherName': teacherName,
        'mode': mode,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Attendance entry failed: ${res.body}');
    }
  }

  static Future<void> markExit({
    required String teacherId,
  }) async {
    final uri = Uri.parse('$baseUrl/attendance/exit');

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'teacherId': teacherId,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Attendance exit failed: ${res.body}');
    }
  }

}



