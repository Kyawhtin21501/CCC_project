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
  // print("####################################Post User Input${payload.toString()}##################################################");
    return await http.post(
      Uri.parse('$baseUrl/user_input'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }
//post /fetch prediction for dashboard -->kyipyar hlaing -------->old version
// static Future<Map<String, dynamic>> fetchShiftAndPrediction(Map<String, dynamic> payload) async {
//   final response = await http.post(
//     Uri.parse('$baseUrl/shift_table/dashboard'),
//     headers: {"Content-Type": "application/json"},
//     body: jsonEncode(payload),
//   );
//  //print("####################################fetched prediction${response.body}#######in api_service.dart###########################################");
//   if (response.statusCode == 200) {
//     return jsonDecode(response.body);
//   } else {
//     throw Exception('Failed to fetch shift data: ${response.statusCode}');
//   }
// }

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

  // ---- Fetch predicted sales for dashboard ----
  static Future<List<Map<String, dynamic>>> getPredSales() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/pred_sale/dashboard"));
print("####################################fetched sale prediction${response.statusCode}#####${response.body}##in api_service.dart ###########################################");
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to fetch predicted sales: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching predicted sales: $e");
    }
  }




  //  POST /services/staff (create) completed-->kyipyar hlaing
  static Future<http.Response> postStaffProfile(Map<String, dynamic> payload) async {
   // print("####################################Post User Input${payload.toString()}#######Post Staff profile form api_service.dart###########################################");
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


  //PUT /services/staff/{id} completed -->kyipyar hlaing
  static Future<http.Response> updateStaffProfile(int id, Map<String, dynamic> updates) async {
   // print("---------------------------------------${updates.toString()}----------for updating staff profile-------------------------------------------------");
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

  //Optional GET /services/staff/search?term={term}&by={ID|Name}
  static Future<http.Response> searchStaff(String term, {String by = "ID"}) async {
    final url = Uri.parse('$baseUrl/services/staff/search?term=$term&by=$by');
    return await http.get(url);
  }


}
