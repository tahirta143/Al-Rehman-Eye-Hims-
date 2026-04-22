import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';
import '../../models/mr_model/mr_patient_model.dart';

class MrApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── GET /api/mr-data ──────────────────────────────────────────────
  Future<MrPatientsResult> fetchAllPatients({
    int page = 1,
    int limit = 50,
    String search = '',
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('${GlobalApi.baseUrl}/mr-data')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return MrPatientsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final patientsJson = data['data'] as List<dynamic>;
          final patients = patientsJson
              .map((json) =>
              MrPatientApiModel.fromJson(json as Map<String, dynamic>))
              .toList();

          final count = data['count'] as int? ?? patients.length;
          final currentPage = data['currentPage'] as int? ?? page;
          final totalPages = data['totalPages'] as int? ?? 1;

          return MrPatientsResult(
            success: true,
            patients: patients,
            count: count,
            currentPage: currentPage,
            totalPages: totalPages,
          );
        }

        return MrPatientsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch patients',
        );
      }

      return MrPatientsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return MrPatientsResult(
        success: false,
        message: 'Failed to fetch patients: $e',
      );
    }
  }

  // ─── GET /api/mr-data/:mr ──────────────────────────────────────────
  Future<MrPatientResult> fetchPatientByMR(String mrNumber) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
        Uri.parse('${GlobalApi.baseUrl}/mr-data/$mrNumber'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return MrPatientResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final patientJson = data['data'] as Map<String, dynamic>;

          // ✅ Extract history array from response data
          final historyRaw = patientJson['history'];
          final List<dynamic> historyList =
          historyRaw is List ? historyRaw : [];

          // ✅ Build enriched map with history explicitly set
          final patientWithHistory = Map<String, dynamic>.from(patientJson)
            ..['history'] = historyList;

          final patient = MrPatientApiModel.fromJson(patientWithHistory);
          return MrPatientResult(success: true, patient: patient);
        }

        return MrPatientResult(
          success: false,
          message: data['message'] as String? ?? 'Patient not found',
        );
      }

      if (response.statusCode == 404) {
        return MrPatientResult(
          success: false,
          message: 'Patient not found',
          notFound: true,
        );
      }

      return MrPatientResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return MrPatientResult(
        success: false,
        message: 'Failed to fetch patient: $e',
      );
    }
  }

  // ─── GET /api/mr-data/next-mr ──────────────────────────────────────
  Future<NextMrResult> fetchNextMRNumber() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
        Uri.parse('${GlobalApi.baseUrl}/mr-data/next-mr'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return NextMrResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final nextMr = (data['nextMr'] ?? data['nextMR']) as String;
          return NextMrResult(success: true, nextMR: nextMr);
        }

        return NextMrResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to get next MR',
        );
      }

      return NextMrResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return NextMrResult(
        success: false,
        message: 'Failed to get next MR: $e',
      );
    }
  }

  // ─── POST /api/mr-data ─────────────────────────────────────────────
  Future<CreatePatientResult> createPatient(
      Map<String, dynamic> patientData) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
        Uri.parse('${GlobalApi.baseUrl}/mr-data'),
        headers: headers,
        body: jsonEncode(patientData),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return CreatePatientResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          final patientJson = data['data'] as Map<String, dynamic>;
          final patient = MrPatientApiModel.fromJson(patientJson);
          return CreatePatientResult(
            success: true,
            message:
            data['message'] as String? ?? 'Patient created successfully',
            patient: patient,
          );
        }
      }

      return CreatePatientResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to create patient',
      );
    } catch (e) {
      return CreatePatientResult(
        success: false,
        message: 'Failed to create patient: $e',
      );
    }
  }

  // ─── PUT /api/mr-data/:mr ──────────────────────────────────────────
  Future<UpdatePatientResult> updatePatient(
      String mrNumber, Map<String, dynamic> patientData) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(
        Uri.parse('${GlobalApi.baseUrl}/mr-data/$mrNumber'),
        headers: headers,
        body: jsonEncode(patientData),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return UpdatePatientResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final patientJson = data['data'] as Map<String, dynamic>;
          final patient = MrPatientApiModel.fromJson(patientJson);
          return UpdatePatientResult(
            success: true,
            message:
            data['message'] as String? ?? 'Patient updated successfully',
            patient: patient,
          );
        }
      }

      return UpdatePatientResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to update patient',
      );
    } catch (e) {
      return UpdatePatientResult(
        success: false,
        message: 'Failed to update patient: $e',
      );
    }
  }

  // ─── DELETE /api/mr-data/:mr ───────────────────────────────────────
  Future<DeletePatientResult> deletePatient(String mrNumber) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
        Uri.parse('${GlobalApi.baseUrl}/mr-data/$mrNumber'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return DeletePatientResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return DeletePatientResult(
            success: true,
            message:
            data['message'] as String? ?? 'Patient deleted successfully',
          );
        }
      }

      return DeletePatientResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to delete patient',
      );
    } catch (e) {
      return DeletePatientResult(
        success: false,
        message: 'Failed to delete patient: $e',
      );
    }
  }
}

// ─── Result Classes ────────────────────────────────────────────────

class MrPatientsResult {
  final bool success;
  final List<MrPatientApiModel> patients;
  final int count;
  final int currentPage;
  final int totalPages;
  final String? message;

  MrPatientsResult({
    required this.success,
    this.patients = const [],
    this.count = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.message,
  });
}

class MrPatientResult {
  final bool success;
  final MrPatientApiModel? patient;
  final String? message;
  final bool notFound;

  MrPatientResult({
    required this.success,
    this.patient,
    this.message,
    this.notFound = false,
  });
}

class NextMrResult {
  final bool success;
  final String? nextMR;
  final String? message;

  NextMrResult({
    required this.success,
    this.nextMR,
    this.message,
  });
}

class CreatePatientResult {
  final bool success;
  final String? message;
  final MrPatientApiModel? patient;

  CreatePatientResult({
    required this.success,
    this.message,
    this.patient,
  });
}

class UpdatePatientResult {
  final bool success;
  final String? message;
  final MrPatientApiModel? patient;

  UpdatePatientResult({
    required this.success,
    this.message,
    this.patient,
  });
}

class DeletePatientResult {
  final bool success;
  final String? message;

  DeletePatientResult({
    required this.success,
    this.message,
  });
}