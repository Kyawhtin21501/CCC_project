import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Set this to your backend address. Replace with actual IP or domain in production.
  static const String baseUrl = 'http://127.0.0.1:5000';

  // GET /staff_list completed -->kyipyar hlaing
  static Future<List<String>> fetchStaffList() async {
    final response = await http.get(Uri.parse('$baseUrl/staff_list'));//check this url -->kyaw Htin Hein
    // print("########## [ApiService] Status: ${response.statusCode} ##########");
    // print("########## [ApiService] /staff_list response: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<String>();
    } else {
      throw Exception('Failed to load staff list');
    }
  }

  // Optional parser (if backend returns full profiles with ID/Name/etc.)
  static List<Map<String, String>> _parseStaffList(String responseBody) {
    final List<dynamic> data = jsonDecode(responseBody);
    return data.map((e) => {
      'ID': e['ID'].toString(),
      'Name': e['Name'].toString(),
    }).toList();
  }

  // POST /user_input completed -->kyipyar hlaing
  static Future<http.Response> postUserInput(Map<String, dynamic> payload) async {
  //  print("####################################Post User Input${payload.toString()}##################################################");
    return await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  // POST /services/sale_prediction_staff_count
  static Future<http.Response> postPrediction(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/services/sale_prediction_staff_count'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  //  POST /services/staff (create) completed-->kyipyar hlaing
  static Future<http.Response> postStaffProfile(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/services/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  // POST /shift from staff with id like-- Kyi Pyar Hlaing IDnum Moring -False,Lunch-False, Night-True
  static Future<void> saveShiftPreferences(Map<String, dynamic> data) async {
    print("========================${data.toString()}= in api_service.dart ===========================");
    final response = await http.post(
      
      Uri.parse('$baseUrl/save_shift_preferences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^${response.statusCode}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
      throw Exception('Failed to save preferences');
    }
  }


  //PUT /services/staff/{id}
  static Future<http.Response> updateStaffProfile(int id, Map<String, dynamic> updates) async {
    return await http.put(
      Uri.parse('$baseUrl/services/staff/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
  }

  // DELETE /services/staff/{id} completed -->kyipyar hlaing
  static Future<http.Response> deleteStaffProfile(int id) async {
    return await http.delete(
      Uri.parse('$baseUrl/services/staff/$id'),
    );
  }

  // GET /services/staff/search?term={term}&by={ID|Name}
  static Future<http.Response> searchStaff(String term, {String by = "ID"}) async {
    final url = Uri.parse('$baseUrl/services/staff/search?term=$term&by=$by');
    return await http.get(url);
  }

}
