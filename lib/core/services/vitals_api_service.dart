import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';

class VitalsApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> saveVitals(Map<String, dynamic> data) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/vitals'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVitalsByMR(String mrNumber) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/vitals/mr/$mrNumber'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVitalsByReceipt(String receiptId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/vitals/receipt/$receiptId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getVitalsHistory(String mrNumber) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/vitals/history/$mrNumber'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
