import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';

class PharmacyApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Pharmacy Bootstrap ---
  Future<Map<String, dynamic>> getPharmacyBootstrap() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/bootstrap'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Medicines CRUD ---
  Future<Map<String, dynamic>> getAllMedicines() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/medicines'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createMedicine(Map<String, dynamic> data) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/medicines'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMedicine(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('${GlobalApi.baseUrl}/medicines/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteMedicine(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('${GlobalApi.baseUrl}/medicines/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Opening Balances ---
  Future<Map<String, dynamic>> getOpeningBalanceRows(Map<String, dynamic> params) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${GlobalApi.baseUrl}/pharmacy/opening-balances').replace(
        queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
      );
      final response = await http.get(uri, headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveOpeningBalances(Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/opening-balances'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Stock Search ---
  Future<Map<String, dynamic>> searchPharmacyMedicines(String query) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/stock/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Purchases ---
  Future<Map<String, dynamic>> createPurchase(Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/purchases'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Sales ---
  Future<Map<String, dynamic>> getPatientByMR(String mr) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/mr-data/$mr'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/sales'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveHeldSale(Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/sales/hold'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSaleById(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/sales/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAndFinalizeSale(int id, Map<String, dynamic> payload) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/sales/$id'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteHeldSale(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/sales/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Prescribed Patients ---
  Future<Map<String, dynamic>> getPrescribedPatients() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/prescribed-patients'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPrescribedPatientById(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/prescribed-patients/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePrescribedPatient(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('${GlobalApi.baseUrl}/pharmacy/prescribed-patients/$id'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Company Settings ---
  Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/company-settings'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
