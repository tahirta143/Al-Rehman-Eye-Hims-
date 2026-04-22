import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';

class NutritionApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> saveNutritionistPrescription(Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/nutritionist-prescriptions'),
        headers: headers,
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchNutritionistPrescriptionById(int id) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/nutritionist-prescriptions/$id'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchNutritionistPrescriptionHistory(String mrNumber) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/nutritionist-prescriptions/history/$mrNumber'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
