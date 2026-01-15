import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Centralized service for handling all API communication between the Flutter frontend 
/// and the Flask backend.
class ApiService {
  // ============================================================
  // CONFIGURATION & TRACING
  // ============================================================

  /// Automatically switches the API URL based on build mode.
  /// Release mode points to the production server (Render), 
  /// while Debug mode points to the local machine (localhost).
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://ccc-project-p8yt.onrender.com";
    }
    return 'http://100.64.1.81:5000';//have to use local network IP for device testing!!!!!
  }

  /// Default headers used for JSON-based communication.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Helper to determine if a network request was successful (2xx status codes).
  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  /// Internal logger that only operates in Debug mode to prevent 
  /// leaking sensitive URL info in production.
  static void _trace(String message) {
    if (kDebugMode) {
      print('[ApiService] $message');
    }
  }

  // ============================================================
  // STAFF API LOGIC
  // ============================================================

  /// Maps backend-friendly keys to UI-friendly Japanese labels.
  static const Map<String, String> _translationMap = {
    'part-time': 'パートタイム',
    'full-time': 'フルタイム',
    'high-school': '高校生',
    'international': '留学生',
  };

  /// Sanitizes raw data from the server by translating status codes to Japanese.
  static Map<String, dynamic> _sanitizeStaffData(Map<String, dynamic> staff) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(staff);
    if (_translationMap.containsKey(result['status'])) {
      result['status'] = _translationMap[result['status']];
    }
    return result;
  }

  /// Reverses Japanese labels back to backend-friendly keys before sending to the server.
  static Map<String, dynamic> _deSanitizeStaffData(Map<String, dynamic> staff) {
    final reverseMap = _translationMap.map((k, v) => MapEntry(v, k));
    final Map<String, dynamic> result = Map<String, dynamic>.from(staff);
    if (reverseMap.containsKey(result['status'])) {
      result['status'] = reverseMap[result['status']];
    }
    return result;
  }

  /// GET: Retrieves all staff members and decodes with UTF-8 support for Japanese characters.
  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    final url = '$baseUrl/staff';
    _trace('GET: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (_isSuccess(response.statusCode)) {
  final List data = jsonDecode(utf8.decode(response.bodyBytes));
  return data.map((e) => _sanitizeStaffData(Map<String, dynamic>.from(e))).toList();
} else {
  // This provides more info in the console
  _trace('Server side error: ${response.body}'); 
  throw 'サーバーエラーが発生しました (${response.statusCode})。管理者にお問い合わせください。';
}
      
    } catch (e) {
      _trace('fetchStaffList Error: $e');
      rethrow;
    }
  }

  /// POST: Adds a new staff member. Data is de-sanitized before sending.
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

  /// PATCH: Partially updates an existing staff member by ID.
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

  /// DELETE: Removes a staff member from the database.
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

  /// POST: Saves staff shift preferences for the scheduling algorithm.
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

  /// POST: Fetches predicted sales for the dashboard for the upcoming week.
  static Future<List<Map<String, dynamic>>> fetchPredSalesOneWeek() async {
    final url = '$baseUrl/pred_sales_dash';
    _trace('POST Sales: $url');
    try {
      // Note: This uses POST as requested by backend to potentially allow date range filtering
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

  /// GET: Retrieves historical daily reports.
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

  /// POST: Submits new daily report data (e.g., actual sales, foot traffic).
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

  /// GET: Fetches shift assignments specifically for "Today" and "Tomorrow" 
  /// to display on the main dashboard.
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
        
        // Frontend filtering to ensure only relevant immediate shifts are shown
        return decoded.map((e) => Map<String, dynamic>.from(e)).where((shift) {
          try {
            DateTime shiftDate = DateTime.parse(shift['date'].toString());
            DateTime cleanShiftDate = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
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

  /// POST: Triggers the AI shift generation algorithm for a specific date range.
  static Future<List<Map<String, dynamic>>> fetchAutoShiftTable(DateTime start, DateTime end) async {
    final url = '$baseUrl/shift_ass';
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
        return List<Map<String, dynamic>>.from(decoded);
      }
      throw "AI shift generation failed";
    } catch (e) {
      _trace('fetchAutoShiftTable Error: $e');
      rethrow;
    }
  }
}