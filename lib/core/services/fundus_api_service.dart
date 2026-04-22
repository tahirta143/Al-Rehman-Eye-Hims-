import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';

class FundusApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> saveFundusExaminationsBulk(Map<String, dynamic> data) async {
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/fundus-examinations/bulk'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchFundusHistory(String mrNumber) async {
    try {
      final headers = await _headers();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/fundus-examinations/history/$mrNumber'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
