import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  // ============================================================
  // CONFIGURATION & TRACING
  // ============================================================

  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://ccc-project.onrender.com';
    }
    return 'http://127.0.0.1:5000';
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  /// Simple trace function to monitor API flow in debug mode
  static void _trace(String message) {
    if (kDebugMode) {
      print('[ApiService] $message');
    }
  }

  // ============================================================
  // STAFF API LOGIC
  // ============================================================

  static const Map<String, String> _translationMap = {
    'part-time': 'パートタイム',
    'full-time': 'フルタイム',
    'high-school': '高校生',
    'international': '留学生',
  };

  static Map<String, dynamic> _sanitizeStaffData(Map<String, dynamic> staff) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(staff);
    if (_translationMap.containsKey(result['status'])) {
      result['status'] = _translationMap[result['status']];
    }
    return result;
  }

  static Map<String, dynamic> _deSanitizeStaffData(Map<String, dynamic> staff) {
    final reverseMap = _translationMap.map((k, v) => MapEntry(v, k));
    final Map<String, dynamic> result = Map<String, dynamic>.from(staff);
    if (reverseMap.containsKey(result['status'])) {
      result['status'] = reverseMap[result['status']];
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    final url = '$baseUrl/staff';
    _trace('GET: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => _sanitizeStaffData(Map<String, dynamic>.from(e))).toList();
      }
      throw 'Error: ${response.statusCode}';
    } catch (e) {
      _trace('fetchStaffList Error: $e');
      rethrow;
    }
  }

  static Future<void> postStaffProfile(Map<String, dynamic> staffData) async {
    final url = '$baseUrl/staff';
    final cleanedData = _deSanitizeStaffData(staffData);
    _trace('POST: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );
      if (!_isSuccess(response.statusCode)) throw 'Post Failed';
    } catch (e) {
      _trace('postStaffProfile Error: $e');
      rethrow;
    }
  }

  static Future<void> patchStaffProfile(int staffId, Map<String, dynamic> staffData) async {
    final url = '$baseUrl/staff/$staffId';
    final cleanedData = _deSanitizeStaffData(staffData);
    _trace('PATCH: $url');
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );
      if (!_isSuccess(response.statusCode)) throw 'Update Failed';
    } catch (e) {
      _trace('patchStaffProfile Error: $e');
      rethrow;
    }
  }

  static Future<void> deleteStaffProfile(int staffId) async {
    final url = '$baseUrl/staff/$staffId';
    _trace('DELETE: $url');
    try {
      final response = await http.delete(Uri.parse(url), headers: _headers);
      if (!_isSuccess(response.statusCode)) throw 'Delete Failed';
    } catch (e) {
      _trace('deleteStaffProfile Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // SHIFTS & REPORTS
  // ============================================================

  static Future<void> saveShiftPreferences(Map<String, dynamic> payload) async {
    final url = '$baseUrl/shift_pre';
    _trace('POST Preferences: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (!_isSuccess(response.statusCode)) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw error['message'] ?? '保存に失敗しました';
      }
    } catch (e) {
      _trace('saveShiftPreferences Error: $e');
      rethrow;
    }
  }



  static Future<List<Map<String, dynamic>>> fetchPredSalesOneWeek() async {
    final url = '$baseUrl/pred_sales_dash';
    _trace('POST Sales: $url');
    try {
      final response = await http.post(Uri.parse(url), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw "売上予測取得失敗";
    } catch (e) {
      _trace('fetchPredSalesOneWeek Error: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchDailyReports() async {
    final url = '$baseUrl/daily_report';
    _trace('GET Reports: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw '日報データ取得失敗';
    } catch (e) {
      _trace('fetchDailyReports Error: $e');
      rethrow;
    }
  }

  static Future<void> postUserInput(Map<String, dynamic> payload) async {
    final url = '$baseUrl/daily_report';
    _trace('POST DailyInput: $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(payload),
      );
      if (!_isSuccess(response.statusCode)) throw "送信失敗";
    } catch (e) {
      _trace('postUserInput Error: $e');
      rethrow;
    }
  }
static Future<List<Map<String, dynamic>>> fetchTodayShiftAssignment() async {
  final url = '$baseUrl/shift_ass_dash_board';

  _trace('GET Dashboard Shifts: $url');
  try {
    final response = await http.get(Uri.parse(url), headers: _headers);
    
    if (_isSuccess(response.statusCode)) {
      final List decoded = jsonDecode(utf8.decode(response.bodyBytes));
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      return decoded.map((e) => Map<String, dynamic>.from(e)).where((shift) {
        try {
          DateTime shiftDate = DateTime.parse(shift['date'].toString());
          DateTime cleanShiftDate = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
          
          // 🔥 Change: Allow both today and tomorrow
          return cleanShiftDate.isAtSameMomentAs(today) || 
                 cleanShiftDate.isAtSameMomentAs(tomorrow);
        } catch (_) {
          return false;
        }
      }).toList();
    }
    throw "Failed to fetch dashboard data";
  } catch (e) {
    _trace('fetchTodayShiftAssignment Error: $e');
    rethrow;
  }
}

  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    final url = '$baseUrl/shift_pre';
    _trace('GET Dashboard: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (_isSuccess(response.statusCode)) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      _trace('fetchShiftTableDashboard Error: $e');
      rethrow;
    }
  }
  static Future<List<Map<String, dynamic>>> fetchAutoShiftTable(DateTime start, DateTime end) async {
  final url = '$baseUrl/shift_ass'; // Matches the @shift_ass_bp.post
  final payload = {
    "start_date": DateFormat('yyyy-MM-dd').format(start),
    "end_date": DateFormat('yyyy-MM-dd').format(end),
  };
  
  _trace('POST AutoShift: $url');
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // The backend returns a list of dicts directly from shift_save_db()
      return List<Map<String, dynamic>>.from(decoded);
    }
    throw "AI shift generation failed";
  } catch (e) {
    _trace('fetchAutoShiftTable Error: $e');
    rethrow;
  }
}
}