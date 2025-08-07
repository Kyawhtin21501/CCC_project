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
      return data.map((name) => name.toString()).toList();
    } else {
      throw Exception('Failed to load staff list');
    }
  }



  // Optional parser (if backend returns full profiles with ID
static Future<Map<String, dynamic>> fetchStaffById(int id) async {
  final response = await http.get(Uri.parse('$baseUrl/services/staff/$id'));
  print("DEBUG: GET request to $baseUrl/services/staff/$id");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch staff: ${response.body}');
  }
}

  // POST /user_input completed -->kyipyar hlaing
  static Future<http.Response> postUserInput(Map<String, dynamic> payload) async {
   print("####################################Post User Input${payload.toString()}##################################################");
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
    print("####################################Post User Input${payload.toString()}#######Post Staff profile###########################################");
    return await http.post(
      Uri.parse('$baseUrl/services/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  // POST /shift from staff with id like-- Kyi Pyar Hlaing IDnum Moring -False,Lunch-False, Night-True
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
//shift_staff_pre.dart 
  static Future<Map<String, dynamic>?> fetchShiftData({
    required String startDate,
    required String endDate,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "start_date": startDate,
          "end_date": endDate,
          "latitude": latitude,
          "longitude": longitude
        }),
      );
print("==================================${response.body}=====in api_service file ============================================");
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load shift data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching shift data: $e');
      return null;
    }
  }

}
