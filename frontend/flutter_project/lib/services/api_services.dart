import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
static String get baseUrl { if (kReleaseMode) { return 'https://ccc-project.onrender.com'; } return 'http://127.0.0.1:5000'; }
  // Common headers for all requests

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
  // ============================================================
  // PRETTY JSON DEBUG UTILITIES
  // ============================================================

  static const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

  static void _logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    debugPrint("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("📤 API REQUEST");
    debugPrint("METHOD : $method");
    debugPrint("URL    : $url");
    debugPrint("HEADERS:\n${_prettyJson.convert(headers)}");
    if (body != null) {
      debugPrint("BODY:\n${_prettyJson.convert(body)}");
    }
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  }

  static void _logResponse(http.Response response) {
    debugPrint("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("📥 API RESPONSE");
    debugPrint("STATUS : ${response.statusCode}");
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      debugPrint("BODY:\n${_prettyJson.convert(decoded)}");
    } catch (_) {
      debugPrint("BODY:\n${utf8.decode(response.bodyBytes)}");
    }
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  }

  // ============================================================
  // STAFF API
  // ============================================================

  static const Map<String, String> _translationMap = {
    'part-time': 'パートタイム',
    'full-time': 'フルタイム',
    'high-school': '高校生',
    'international': '留学生',
  };

  static Map<String, dynamic> _sanitizeStaffData(
      Map<String, dynamic> staff) {
    if (_translationMap.containsKey(staff['status'])) {
      staff['status'] = _translationMap[staff['status']];
    }
    return staff;
  }

  static Map<String, dynamic> _deSanitizeStaffData(
      Map<String, dynamic> staff) {
    final reverseMap =
        _translationMap.map((k, v) => MapEntry(v, k));
    if (reverseMap.containsKey(staff['status'])) {
      staff['status'] = reverseMap[staff['status']];
    }
    return staff;
  }

  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    final url = '$baseUrl/staff';

    try {
      _logRequest(method: "GET", url: url, headers: _headers);

      final response =
          await http.get(Uri.parse(url), headers: _headers);

      _logResponse(response);

      if (_isSuccess(response.statusCode)) {
        final List data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((e) => _sanitizeStaffData(
                Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw 'サーバーエラー (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] fetchStaffList Error: $e");
      rethrow;
    }
  }

  static Future<void> postStaffProfile(
      Map<String, dynamic> staffData) async {
    final url = '$baseUrl/staff';
    final cleanedData =
        _deSanitizeStaffData(Map<String, dynamic>.from(staffData));

    try {
      _logRequest(
        method: "POST",
        url: url,
        headers: _headers,
        body: cleanedData,
      );

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );

      _logResponse(response);

      if (!_isSuccess(response.statusCode)) {
        throw '保存に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] postStaffProfile Error: $e");
      rethrow;
    }
  }

  static Future<void> patchStaffProfile(
      int staffId, Map<String, dynamic> staffData) async {
    final url = '$baseUrl/staff/$staffId';
    final cleanedData =
        _deSanitizeStaffData(Map<String, dynamic>.from(staffData));

    try {
      _logRequest(
        method: "PATCH",
        url: url,
        headers: _headers,
        body: cleanedData,
      );

      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(cleanedData),
      );

      _logResponse(response);

      if (!_isSuccess(response.statusCode)) {
        throw '更新に失敗しました (${response.statusCode})';
      }
    } catch (e) {
      debugPrint("[ApiService] patchStaffProfile Error: $e");
      rethrow;
    }
  }

  static Future<void> deleteStaffProfile(int staffId) async {
    final url = '$baseUrl/staff/$staffId';

    try {
      _logRequest(method: "DELETE", url: url, headers: _headers);

      final response =
          await http.delete(Uri.parse(url), headers: _headers);

      _logResponse(response);

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

  static Future<void> saveShiftPreferences(
      Map<String, dynamic> payload) async {
    final url = '$baseUrl/shift_pre';

    try {
      _logRequest(
          method: "POST", url: url, headers: _headers, body: payload);

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(payload),
      );

      _logResponse(response);

      if (!_isSuccess(response.statusCode)) {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw error['message'] ?? '保存に失敗しました';
      }
    } catch (e) {
      debugPrint("[ApiService] saveShiftPreferences Error: $e");
      rethrow;
    }
  }

static Future<List<Map<String, dynamic>>> fetchAutoShiftTable(
    DateTime start, DateTime end) async {
  final url = '$baseUrl/shift_ass';
  final formatter = DateFormat('yyyy-MM-dd');

  final payload = {
    "start_date": formatter.format(start),
    "end_date": formatter.format(end),
  };

  try {
    _logRequest(
      method: "POST",
      url: url,
      headers: _headers,
      body: payload,
    );

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _logResponse(response);

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      List<Map<String, dynamic>> schedule;

      // If backend returns a Map with "shift_schedule"
      if (decoded is Map && decoded.containsKey("shift_schedule")) {
        schedule = (decoded["shift_schedule"] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } 
      // If backend returns a raw List
      else if (decoded is List) {
        schedule = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } 
      // Otherwise, empty list
      else {
        schedule = [];
      }

      return schedule;
    } else {
      throw "AI shift generation failed (${response.statusCode})";
    }
  } catch (e) {
    debugPrint("[ApiService] fetchAutoShiftTable Error: $e");
    rethrow;
  }
}

  // ============================================================
  // DASHBOARD
  // ============================================================

  static Future<List<Map<String, dynamic>>> fetchPredSalesOneWeek() async {
    final url = '$baseUrl/pred_sales_dash';

    try {
      _logRequest(method: "POST", url: url, headers: _headers);

      final response =
          await http.post(Uri.parse(url), headers: _headers);

      _logResponse(response);

      if (_isSuccess(response.statusCode)) {
        final List data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        throw "売上予測取得失敗";
      }
    } catch (e) {
      debugPrint("[ApiService] fetchPredSalesOneWeek Error: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    final url = '$baseUrl/shift_pre';

    try {
      _logRequest(method: "GET", url: url, headers: _headers);

      final response =
          await http.get(Uri.parse(url), headers: _headers);

      _logResponse(response);

      if (_isSuccess(response.statusCode)) {
        final List data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
// ============================================================
// DAILY REPORT
// ============================================================

static Future<List<Map<String, dynamic>>> fetchDailyReports() async {
  final url = '$baseUrl/daily_report';

  try {
    _logRequest(
      method: "GET",
      url: url,
      headers: _headers,
    );

    final response =
        await http.get(Uri.parse(url), headers: _headers);

    _logResponse(response);

    if (_isSuccess(response.statusCode)) {
      final List data =
          jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      throw '日報データ取得失敗 (${response.statusCode})';
    }
  } catch (e) {
    debugPrint("[ApiService] fetchDailyReports Error: $e");
    rethrow;
  }
}

  static Future<void> postUserInput(
      Map<String, dynamic> payload) async {
    final url = '$baseUrl/daily_report';

    try {
      _logRequest(
          method: "POST", url: url, headers: _headers, body: payload);

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(payload),
      );

      _logResponse(response);

      if (!_isSuccess(response.statusCode)) {
        throw "送信失敗";
      }
    } catch (e) {
      rethrow;
    }
  }
}
