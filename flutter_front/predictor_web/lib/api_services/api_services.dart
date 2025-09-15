import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000'; // update for production

  // ---- GET staff list ----
  static Future<List<String>> fetchStaffList() async {
    final response = await http.get(Uri.parse('$baseUrl/staff_list'));
    if (kDebugMode) {
      print("[ApiService] GET /staff_list -> ${response.statusCode}");
    }

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((name) => name.toString()).toList();
    } else {
      throw Exception('Failed to load staff list');
    }
  }

  // ---- GET staff by ID ----
  static Future<Map<String, dynamic>> fetchStaffById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/services/staff/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch staff: ${response.body}');
    }
  }

  // ---- POST /user_input ----
  static Future<http.Response> postUserInput(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      print("[ApiService] POST /user_input payload: $payload");
    }
    return await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

//updated shift prediction for  usage in dashboard
  static Future<List<Map<String, dynamic>>> fetchShiftTableDashboard() async {
    final url = Uri.parse("$baseUrl/shift_table/dashboard");
    final response = await http.get(url);
print("####################################fetched shift prediction${response.statusCode}#####${response.body}##in api_service.dart###########################################");
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception("Failed to load shift table");
    }
  }

  // ---- POST auto shift generation ----
  static Future<List<Map<String, dynamic>>> fetchAutoShiftTableDashboard(
      DateTime start, DateTime end) async {
    final url = Uri.parse("$baseUrl/shift");
    final formatter = DateFormat('yyyy-MM-dd');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "start_date": formatter.format(start),
        "end_date": formatter.format(end),
      }),
    );
    //added for debug

    if (kDebugMode) {
      print(
          "[ApiService] POST /shift with start: ${formatter.format(start)}, end: ${formatter.format(end)} -> ${response.statusCode}");
    }
    //add response body for debug
    if (kDebugMode) {
      print("[ApiService] Response body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonData["shift_schedule"]);
    } else {
      throw Exception("Failed to fetch auto shift table: ${response.body}");
    }
  }

  // ---- GET predicted sales (dashboard) ----
  static Future<List<Map<String, dynamic>>> getPredSales() async {
    final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"));
    if (kDebugMode) {
      print("[ApiService] GET /pred_sale/dashboard -> ${response.statusCode}");
    }
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Failed to fetch predicted sales: ${response.statusCode}");
    }
  }

  // ---- POST create staff ----
  static Future<http.Response> postStaffProfile(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/services/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  // ---- POST shift preferences ----
  static Future<void> saveShiftPreferences(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_shift_preferences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save preferences');
    }
  }

  // ---- PUT update staff ----
  static Future<http.Response> updateStaffProfile(int id, Map<String, dynamic> updates) async {
    return await http.put(
      Uri.parse('$baseUrl/services/staff/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
  }

  // ---- DELETE staff ----
  static Future<http.Response> deleteStaffProfile(int id) async {
    return await http.delete(Uri.parse('$baseUrl/services/staff/$id'));
  }

  // ---- GET search staff ----
  static Future<http.Response> searchStaff(String term, {String by = "ID"}) async {
    final url = Uri.parse('$baseUrl/services/staff/search?term=$term&by=$by');
    return await http.get(url);
  }
}
