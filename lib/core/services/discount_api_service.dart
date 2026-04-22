import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import '../../models/voucher_model/voucher_model.dart';
import 'auth_storage_service.dart';

class DiscountApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<DiscountType>> fetchDiscountTypes() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/discount-types'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((e) => DiscountType.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DiscountAuthorityModel>> fetchAuthorities() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/discount-authorities'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((e) => DiscountAuthorityModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
