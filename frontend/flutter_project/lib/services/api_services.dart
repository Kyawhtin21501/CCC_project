import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for Web/iOS Simulator
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://ccc-project.onrender.com';
    }
    
    // If running on Android Emulator, localhost is 10.0.2.2
    // If running on Web or iOS Simulator, localhost is 127.0.0.1
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  // ============================================================
  // STAFF API
  // ============================================================

  /// HELPER: Converts English database values to Japanese to prevent Dropdown crashes.
  /// This ensures that 'part-time' becomes 'パートタイム' before reaching the UI.
  static Map<String, dynamic> _sanitizeStaffData(Map<String, dynamic> staff) {
    const translationMap = {
      'part-time': 'パートタイム',
      'full-time': 'フルタイム',
      'high-school': '高校生',
      'international': '留学生',
    };

    if (translationMap.containsKey(staff['status'])) {
      staff['status'] = translationMap[staff['status']];
    }
    return staff;
  }

  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff'), headers: _headers);

      if (_isSuccess(response.statusCode)) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List data = jsonDecode(decodedBody);
        
        // Clean and translate all staff data
        return data.map((item) {
          final map = Map<String, dynamic>.from(item);
          return _sanitizeStaffData(map);
        }).toList();
      } else {
        throw 'サーバーエラー: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("[ApiService] fetchStaffList Error: $e");
      rethrow;
    }
  }

  /// PATCH: Updates an existing staff profile. 
  /// URL matches Flask @staff_bp.patch("/staff/<int:staff_id>")
  static Future<void> patchStaffProfile(int staffId, Map<String, dynamic> staffData) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/staff/$staffId'),
        headers: _headers,
        body: jsonEncode(staffData),
      );

      if (!_isSuccess(response.statusCode)) {
        throw '更新に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] patchStaffProfile Error: $e");
      rethrow;
    }
  }

  /// POST: Creates a new staff profile.
  static Future<void> postStaffProfile(Map<String, dynamic> staffData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/staff'),
        headers: _headers,
        body: jsonEncode(staffData),
      );

      if (!_isSuccess(response.statusCode)) {
        throw '保存に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] postStaffProfile Error: $e");
      rethrow;
    }
  }

  /// DELETE: Removes a staff profile.
  /// URL matches Flask @staff_bp.delete("/staff/<int:staff_id>")
  static Future<void> deleteStaffProfile(int staffId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/staff/$staffId'),
        headers: _headers,
      );

      if (!_isSuccess(response.statusCode)) {
        throw '削除に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] deleteStaffProfile Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // SHIFT PREFERENCES
  // ============================================================

  static Future<void> saveShiftPreferences(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift_pre'),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (!_isSuccess(response.statusCode)) {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorData['message'] ?? '保存に失敗しました';
        throw errorMessage; 
      }
    } catch (e) {
      debugPrint("[ApiService] saveShiftPreferences Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // AUTO SHIFT GENERATION
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchAutoShiftTable(
      DateTime start, DateTime end) async {
    try {
      final formatter = DateFormat('yyyy-MM-dd');
      final response = await http.post(
        Uri.parse("$baseUrl/shift"),
        headers: _headers,
        body: jsonEncode({
          "start_date": formatter.format(start),
          "end_date": formatter.format(end),
        }),
      );

      if (_isSuccess(response.statusCode)) {
        final Map<String, dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        final List? schedule = jsonData["shift_schedule"];
        return schedule?.map((item) => Map<String, dynamic>.from(item)).toList() ?? [];
      } else {
        throw "AIシフトの生成に失敗しました (${response.statusCode})";
      }
    } catch (e) {
      debugPrint("[ApiService] fetchAutoShiftTable Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // SALES PREDICTION
  // ============================================================

  static Future<List<Map<String, dynamic>>> getPredSales() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"), headers: _headers);

      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw 'サーバーエラー: ${response.statusCode}';
    } catch (e) {
      debugPrint("[ApiService] getPredSales Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // DASHBOARD & EXTRAS
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/shift/dashboard"), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("[ApiService] fetchShiftTableDashboard Error: $e");
      rethrow;
    }
  }

  static Future<void> postUserInput(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user_input"),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (!_isSuccess(response.statusCode)) throw "送信失敗";
    } catch (e) {
      debugPrint("[ApiService] postUserInput Error: $e");
      rethrow;
    }
  }
}