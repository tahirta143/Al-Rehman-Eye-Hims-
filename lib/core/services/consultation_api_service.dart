import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import 'auth_storage_service.dart';
import '../../models/consultation_model/doctor_model.dart';
import '../../models/consultation_model/appointment_model.dart';

class ConsultationApiService {
  // static const String baseUrl = 'http://10.0.2.2:3001/api';
  final AuthStorageService _storage = AuthStorageService();

  // ─── Helper: build auth headers ───────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── GET doctors ──────────────────────────────────────────────
  Future<DoctorsResult> fetchDoctors({bool isPublic = false}) async {
    try {
      final headers = await _authHeaders();
      final endpoint = isPublic ? '/public/patient/doctors' : '/doctors';
      final url = '${GlobalApi.baseUrl}$endpoint';
      print('--- Fetching Doctors ---');
      print('URL: $url');
      print('Public: $isPublic');
      
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));
      
      print('Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        return DoctorsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final doctorsJson = data['data'] as List<dynamic>;
          final doctors = doctorsJson
              .map((json) => DoctorModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return DoctorsResult(
            success: true,
            doctors: doctors,
          );
        }

        return DoctorsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch doctors',
        );
      }

      return DoctorsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return DoctorsResult(
        success: false,
        message: 'Failed to fetch doctors: $e',
      );
    }
  }

  // ─── GET appointments ─────────────────────────────────────────
  Future<AppointmentsResult> fetchAppointments({bool isPublic = false}) async {
    try {
      final headers = await _authHeaders();
      final endpoint = isPublic ? '/public/patient/appointments/my' : '/appointments';
      
      final response = await http
          .get(Uri.parse('${GlobalApi.baseUrl}$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return AppointmentsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final appointmentsJson = data['data'] as List<dynamic>;
          final appointments = appointmentsJson
              .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return AppointmentsResult(
            success: true,
            appointments: appointments,
          );
        }

        return AppointmentsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch appointments',
        );
      }

      return AppointmentsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return AppointmentsResult(
        success: false,
        message: 'Failed to fetch appointments: $e',
      );
    }
  }

  // ─── POST /api/appointments ────────────────────────────────────────
  Future<CreateAppointmentResult> createAppointment(
      Map<String, dynamic> appointmentData) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
            Uri.parse('${GlobalApi.baseUrl}/appointments'),
            headers: headers,
            body: jsonEncode(appointmentData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return CreateAppointmentResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          // Extract appointment data if available
          final appointmentJson = data['data'] as Map<String, dynamic>?;
          AppointmentModel? appointment;
          
          if (appointmentJson != null) {
            appointment = AppointmentModel.fromJson(appointmentJson);
          }

          return CreateAppointmentResult(
            success: true,
            message: data['message'] as String? ?? 'Appointment created successfully',
            appointment: appointment,
          );
        }
      }

      return CreateAppointmentResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to create appointment',
      );
    } catch (e) {
      return CreateAppointmentResult(
        success: false,
        message: 'Failed to create appointment: $e',
      );
    }
  }

  // ─── GET /api/appointments/slots ───────────────────────────────────
  Future<SlotsResult> fetchSlotsForDoctor({
    required int doctorSrlNo,
    required String date,
  }) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${GlobalApi.baseUrl}/appointments/slots').replace(
        queryParameters: {
          'doctor_srl_no': doctorSrlNo.toString(),
          'date': date,
        },
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return SlotsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final slotsData = data['data'] as Map<String, dynamic>;
          final availableSlots = List<String>.from(slotsData['available_slots'] ?? []);
          final bookedSlots = List<String>.from(slotsData['booked_slots'] ?? []);

          return SlotsResult(
            success: true,
            availableSlots: availableSlots,
            bookedSlots: bookedSlots,
          );
        }

        return SlotsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch slots',
        );
      }

      return SlotsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return SlotsResult(
        success: false,
        message: 'Failed to fetch slots: $e',
      );
    }
  }

  // ─── PUT /api/appointments/:id ─────────────────────────────────────
  Future<CreateAppointmentResult> updateAppointment(
      int id, Map<String, dynamic> appointmentData) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(
            Uri.parse('${GlobalApi.baseUrl}/appointments/$id'),
            headers: headers,
            body: jsonEncode(appointmentData),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return CreateAppointmentResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final appointmentJson = data['data'] as Map<String, dynamic>?;
          AppointmentModel? appointment;
          if (appointmentJson != null) {
            appointment = AppointmentModel.fromJson(appointmentJson);
          }
          return CreateAppointmentResult(
            success: true,
            message: data['message'] as String? ?? 'Appointment updated successfully',
            appointment: appointment,
          );
        }
      }

      return CreateAppointmentResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to update appointment',
      );
    } catch (e) {
      return CreateAppointmentResult(
        success: false,
        message: 'Failed to update appointment: $e',
      );
    }
  }

  // ─── DELETE /api/appointments/:id ──────────────────────────────────
  Future<AppointmentsResult> deleteAppointment(int id) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(
            Uri.parse('${GlobalApi.baseUrl}/appointments/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return AppointmentsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          return AppointmentsResult(success: true);
        }
      }

      return AppointmentsResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to delete appointment',
      );
    } catch (e) {
      return AppointmentsResult(
        success: false,
        message: 'Failed to delete appointment: $e',
      );
    }
  }

  // ─── GET /api/appointments?mr_number=... ───────────────────────────
  Future<AppointmentsResult> fetchAppointmentsByMr(String mrNumber) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${GlobalApi.baseUrl}/appointments').replace(
        queryParameters: {'mr_number': mrNumber},
      );

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return AppointmentsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final appointmentsJson = data['data'] as List<dynamic>;
          final appointments = appointmentsJson
              .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return AppointmentsResult(success: true, appointments: appointments);
        }
        return AppointmentsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch patient history',
        );
      }

      return AppointmentsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return AppointmentsResult(
        success: false,
        message: 'Failed to fetch patient history: $e',
      );
    }
  }
}

// ─── Result Classes ────────────────────────────────────────────────

class DoctorsResult {
  final bool success;
  final List<DoctorModel> doctors;
  final String? message;

  DoctorsResult({
    required this.success,
    this.doctors = const [],
    this.message,
  });
}

class AppointmentsResult {
  final bool success;
  final List<AppointmentModel> appointments;
  final String? message;

  AppointmentsResult({
    required this.success,
    this.appointments = const [],
    this.message,
  });
}

class CreateAppointmentResult {
  final bool success;
  final String? message;
  final AppointmentModel? appointment;

  CreateAppointmentResult({
    required this.success,
    this.message,
    this.appointment,
  });
}

class SlotsResult {
  final bool success;
  final List<String> availableSlots;
  final List<String> bookedSlots;
  final String? message;

  SlotsResult({
    required this.success,
    this.availableSlots = const [],
    this.bookedSlots = const [],
    this.message,
  });
}
