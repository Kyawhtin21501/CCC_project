import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  /// Automatically switch baseUrl depending on debug or release
  static final String baseUrl = kDebugMode
      ? 'http://127.0.0.1:5000'  // Local Flask server
      : 'https://ccc-project.onrender.com';  // Production (Render)

  // ============================================================
  // STAFF API (Matches Flask: /staff, /staff/<id>)
  // ============================================================

  /// GET all staff
  /// Flask endpoint: GET /staff
  static Future<List<Map<String, dynamic>>> fetchStaffList() async {
    final response = await http.get(Uri.parse('$baseUrl/staff'));

    if (kDebugMode) {
      print("[ApiService] GET /staff -> ${response.statusCode}");
      print("[ApiService] Body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((s) => s as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load staff list [${response.statusCode}]');
    }
  }

  /// GET staff by ID
  /// Flask endpoint: GET /staff/<id>
  static Future<Map<String, dynamic>> fetchStaffById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/staff/$id'));

    if (kDebugMode) {
      print("[ApiService] GET /staff/$id -> ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch staff ID=$id: ${response.body}");
    }
  }

  /// POST create new staff
  /// Flask: POST /staff
  static Future<http.Response> postStaffProfile(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  /// PUT update staff info
  /// Flask: PUT /staff/<id>
  static Future<http.Response> updateStaffProfile(int id, Map<String, dynamic> updates) async {
    return await http.put(
      Uri.parse('$baseUrl/staff/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
  }

  /// DELETE staff by ID
  /// Flask: DELETE /staff/<id>
  static Future<http.Response> deleteStaffProfile(int id) async {
    return await http.delete(Uri.parse('$baseUrl/staff/$id'));
  }

  // ============================================================
  // PREDICTION + SHIFT API
  // ============================================================

  /// POST user input (for predictions)
  static Future<http.Response> postUserInput(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      print("[ApiService] POST /daily_report payload: $payload");
    }

    return await http.post(
      Uri.parse('$baseUrl/daily_report'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  /// GET shift table (dashboard)
  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    final url = Uri.parse("$baseUrl/shift_table/dashboard");
    final response = await http.get(url);

    if (kDebugMode) {
      print("[ApiService] GET /shift_table/dashboard -> ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to load shift table");
    }
  }

  /// POST auto shift generation
  static Future<List<Map<String, dynamic>>> fetchAutoShiftTableDashboard(
      DateTime start, DateTime end) async {
    final formatter = DateFormat('yyyy-MM-dd');

    final response = await http.post(
      Uri.parse("$baseUrl/shift"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "start_date": formatter.format(start),
        "end_date": formatter.format(end),
      }),
    );

    if (kDebugMode) {
      print("[ApiService] POST /shift -> ${response.statusCode}");
      print("[ApiService] Body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonData["shift_schedule"]);
    } else {
      throw Exception("Failed to fetch auto shift table: ${response.body}");
    }
  }

  // ============================================================
  // SALES PREDICTION API
  // ============================================================

  /// GET all predicted sales
  static Future<List<Map<String, dynamic>>> getPredSales() async {
    final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"));

    if (kDebugMode) {
      print("[ApiService] GET /pred_sale/dashboard -> ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch predicted sales");
    }
  }

  /// GET today's predicted sales
  static Future<List<Map<String, dynamic>>> getPredSalesToday() async {
    final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"));

    if (kDebugMode) {
      print("[ApiService] GET /pred_sale/dashboard -> ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      final today = DateTime.now();
      final formattedToday =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final filtered = data.where((item) => item['date'] == formattedToday).toList();

      return List<Map<String, dynamic>>.from(filtered);
    } else {
      throw Exception("Failed to fetch predicted sales");
    }
  }

  // ============================================================
  // SHIFT PREFERENCES
  // ============================================================

  /// POST shift preferences
  static Future<void> saveShiftPreferences(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_shift_preferences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save shift preferences');
    }
  }
}
