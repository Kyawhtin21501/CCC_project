import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  static final String baseUrl = kDebugMode
      ? 'http://127.0.0.1:5000'
      : 'https://ccc-project.onrender.com';

  // Helper for headers to avoid repetition
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ============================================================
  // STAFF API
  // ============================================================

  /// GET all staff
  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/staff'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Ensure every item in the list is a Map<String, dynamic>
          return data.map((item) => Map<String, dynamic>.from(item)).toList();
        }
        return [];
      } else {
        throw 'サーバーエラー: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("[ApiService] fetchStaffList Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // SHIFT PREFERENCES
  // ============================================================

  /// POST shift preferences
  /// Expects: { date: "YYYY-MM-DD", staff_id: "...", start_time: "...", end_time: "..." }
  static Future<void> saveShiftPreferences(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_shift_preferences'),
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw errorBody['error'] ?? '保存に失敗しました';
      }
    } catch (e) {
      debugPrint("[ApiService] saveShiftPreferences Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // AUTO SHIFT GENERATION
  // ============================================================

  /// POST to trigger AI Shift Generation
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final List? schedule = jsonData["shift_schedule"];
        
        // Safe mapping to List of Maps
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
      final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw "予測データの取得に失敗しました";
    } catch (e) {
      debugPrint("[ApiService] getPredSales Error: $e");
      rethrow;
    }
  }

  static Future<dynamic> postUserInput(Map<String, dynamic> payload) async {}

  static Future<dynamic> fetchShiftTableDashboard() async {}

  static Future<dynamic> postStaffProfile(Map<String, Object?> staffData) async {}

  static Future<dynamic> deleteStaffProfile(int intId) async {}

  static Future<dynamic> fetchAutoShiftTableDashboard(DateTime autoStart, DateTime autoEnd) async {}
}