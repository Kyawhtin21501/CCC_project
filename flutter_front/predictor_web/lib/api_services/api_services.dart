import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

static Future<List<String>> fetchStaffList() async {
  final response = await http.get(Uri.parse('$baseUrl/staff_list'));
  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<String>();
  } else {
    throw Exception('Failed to load staff list');
  }
}


static List<Map<String, String>> _parseStaffList(String responseBody) {
  final List<dynamic> data = jsonDecode(responseBody);
  return data.map((e) => {
    'ID': e['ID'].toString(),
    'Name': e['Name'].toString(),
  }).toList();
}



  static Future<http.Response> postUserInput(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  static Future<http.Response> postPrediction(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  static Future<http.Response> postStaffProfile(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/services/testing'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  static Future<http.Response> postShiftRequest(Map<String, dynamic> payload) async {
    return await http.post(
      Uri.parse('$baseUrl/shift'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }
}
