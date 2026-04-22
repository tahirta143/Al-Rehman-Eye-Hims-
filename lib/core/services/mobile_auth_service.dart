import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../global/global_api.dart';
import '../../models/mobile_auth_models.dart';

class MobileAuthService {
  final String _baseUrl = GlobalApi.mobileBaseUrl;

  Future<Map<String, dynamic>> registerPatient(PatientRegisterRequest request) async {
    try {
      print('URL: $_baseUrl/auth/register');
      print('Body: ${jsonEncode(request.toJson())}');
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));
      print('Response: ${response.statusCode} - ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Registration Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('OTP send Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(OTPVerifyRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));
      print('Verification Response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Verification Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> loginDoctor(DoctorLoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> loginPatientPortal(PatientPortalLoginRequest request) async {
    try {
      // Patient portal logic uses GlobalApi.baseUrl directly as it's a public endpoint
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/public/patient/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ── Doctor Listing ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listDoctors({String? department, String? search}) async {
    try {
      String url = '$_baseUrl/doctors';
      final params = <String, String>{};
      if (department != null) params['department'] = department;
      if (search != null) params['search'] = search;
      
      if (params.isNotEmpty) {
        url += '?' + Uri(queryParameters: params).query;
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> listDepartments() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/doctors/departments')).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDoctorSlots(String srlNo, String date, {String? token}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$srlNo/slots?date=$date'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ── Patient Portal Specific (Public Endpoints) ──────────────────────────

  Future<Map<String, dynamic>> getPatientPortalDoctorSlots(int srlNo, String date, {String? token}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(
        Uri.parse('${GlobalApi.baseUrl}/public/patient/doctors/$srlNo/slots?date=$date'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ── Appointments ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> bookAppointment(String token, String srlNo, String date, String time) async {
    try {
      print('Booking Appointment: Doctor=$srlNo, Date=$date, Time=$time');
      final response = await http.post(
        Uri.parse('$_baseUrl/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctor_srl_no': srlNo,
          'appointment_date': date,
          'slot_time': time,
        }),
      ).timeout(const Duration(seconds: 10));
      print('Booking Response: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Booking Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createPatientPortalAppointment(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalApi.baseUrl}/public/patient/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> myAppointments(String token) async {
    try {
      print('Fetching My Appointments...');
      final response = await http.get(
        Uri.parse('$_baseUrl/appointments/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('Fetch Appointments Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ── Doctor Dashboard ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDoctorAppointments(String token, String date) async {
    try {
      print('Fetching Doctor Schedule for $date...');
      final response = await http.get(
        Uri.parse('$_baseUrl/doctor/appointments?date=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('Doctor Schedule Error: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPatientRecord(String token, String mrNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/doctor/patient/$mrNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> completeAppointment(String token, String id) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/doctor/appointments/$id/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelAppointment(String token, String id) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/appointments/$id/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
