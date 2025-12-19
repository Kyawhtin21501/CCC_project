import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://ccc-project.onrender.com';
    }
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

  /// Mapping for translations to keep UI and Database in sync
  static const Map<String, String> _translationMap = {
    'part-time': 'パートタイム',
    'full-time': 'フルタイム',
    'high-school': '高校生',
    'international': '留学生',
  };

  /// FROM DB -> TO UI: Converts English strings to Japanese
  static Map<String, dynamic> _sanitizeStaffData(Map<String, dynamic> staff) {
    if (_translationMap.containsKey(staff['status'])) {
      staff['status'] = _translationMap[staff['status']];
    }
    return staff;
  }

  /// FROM UI -> TO DB: Converts Japanese strings back to English for the backend
  static Map<String, dynamic> _deSanitizeStaffData(Map<String, dynamic> staff) {
    final reverseMap = _translationMap.map((k, v) => MapEntry(v, k));
    if (reverseMap.containsKey(staff['status'])) {
      staff['status'] = reverseMap[staff['status']];
    }
    return staff;
  }

  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff'), headers: _headers);

      if (_isSuccess(response.statusCode)) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List data = jsonDecode(decodedBody);
        
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

  static Future<void> patchStaffProfile(int staffId, Map<String, dynamic> staffData) async {
    try {
      // Convert UI Japanese values back to English before sending
      final cleanedData = _deSanitizeStaffData(Map<String, dynamic>.from(staffData));

      final response = await http.patch(
        Uri.parse('$baseUrl/staff/$staffId'),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );

      if (!_isSuccess(response.statusCode)) {
        throw '更新に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] patchStaffProfile Error: $e");
      rethrow;
    }
  }

  static Future<void> postStaffProfile(Map<String, dynamic> staffData) async {
    try {
      // Convert UI Japanese values back to English before sending
      final cleanedData = _deSanitizeStaffData(Map<String, dynamic>.from(staffData));

      final response = await http.post(
        Uri.parse('$baseUrl/staff'),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );
      if(response.statusCode==201){
        debugPrint("Posted successfully");
      }

      if (!_isSuccess(response.statusCode)) {
        throw '保存に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] postStaffProfile Error: $e");
      rethrow;
    }
  }

  static Future<void> deleteStaffProfile(int staffId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/staff/$staffId'),
        headers: _headers,
      );
      if(response.statusCode==200){
        debugPrint("Deleted successfully");
      }

      if (!_isSuccess(response.statusCode)) {
        throw '削除に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] deleteStaffProfile Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // SHIFT PREFERENCES & OTHERS
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
        throw errorData['message'] ?? '保存に失敗しました'; 
      }
    } catch (e) {
      debugPrint("[ApiService] saveShiftPreferences Error: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAutoShiftTable(DateTime start, DateTime end) async {
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
        throw "AIシフトの生成に失敗しました";
      }
    } catch (e) {
      debugPrint("[ApiService] fetchAutoShiftTable Error: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getPredSales() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw 'サーバーエラー';
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/shift/dashboard"), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> postUserInput(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/daily_report"),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        print("Successfully sent Dayily Report data.yayyyyyyyy");
        // Handle successful response
      } 
      if (!_isSuccess(response.statusCode)) throw "送信失敗";
    } catch (e) {
      rethrow;
    }
  }
}