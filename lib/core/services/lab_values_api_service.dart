import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';

class LabValuesApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> fetchLabValuesByMR(String mrNumber) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/lab-values/mr/$mrNumber'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchLabValuesByReceipt(String receiptId) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/lab-values/receipt/$receiptId'),
        headers: headers,
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveLabValues(Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/lab-values'),
        headers: headers,
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
