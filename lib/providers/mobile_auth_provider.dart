import 'package:flutter/material.dart';
import '../core/services/mobile_auth_service.dart';
import '../core/services/auth_storage_service.dart';
import '../models/mobile_auth_models.dart';

class MobileAuthProvider extends ChangeNotifier {
  final MobileAuthService _authService = MobileAuthService();
  final AuthStorageService _storageService = AuthStorageService();

  MobileUser? _currentUser;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _token;
  
  List<dynamic> _portalSlots = [];
  String _portalSlotsMessage = '';
  bool _isLoadingSlots = false;

  MobileUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get otpSent => _otpSent;
  bool get isLoggedIn => _token != null;
  String? get token => _token;
  
  List<dynamic> get portalSlots => _portalSlots;
  String get portalSlotsMessage => _portalSlotsMessage;
  bool get isLoadingSlots => _isLoadingSlots;

  MobileAuthProvider() {
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    _token = await _storageService.getToken();
    if (_token != null) {
      final role = await _storageService.getRole();
      final phone = await _storageService.getUsername();
      final name = await _storageService.getFullName();
      final id = await _storageService.getUserId();

      if (role != null && phone != null) {
        _currentUser = MobileUser(
          id: int.tryParse(id ?? '0') ?? 0,
          phone: phone,
          fullName: name ?? 'User',
          role: role,
        );
      } else {
        _token = null;
      }
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> register(PatientRegisterRequest request) async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.registerPatient(request);
    if (result['success'] == true) {
      _otpSent = true;
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> sendOTP(String phone) async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.sendOTP(phone);
    if (result['success'] == true) {
      _otpSent = true;
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> verifyOTP(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.verifyOTP(OTPVerifyRequest(phone: phone, otp: otp));
    if (result['success'] == true) {
      _token = result['token'];
      _currentUser = MobileUser.fromJson(result['user']);
      await _storageService.saveLoginData(
        token: _token!,
        userId: _currentUser!.id.toString(),
        username: _currentUser!.phone,
        fullName: _currentUser!.fullName,
        role: _currentUser!.role,
      );
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> loginDoctor(String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    final result = await _authService.loginDoctor(DoctorLoginRequest(phone: phone, password: password));
    if (result['success'] == true) {
      _token = result['token'];
      _currentUser = MobileUser.fromJson(result['user']);
      await _storageService.saveLoginData(
        token: _token!,
        userId: _currentUser!.id.toString(),
        username: _currentUser!.phone,
        fullName: _currentUser!.fullName,
        role: _currentUser!.role,
      );
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> loginPatient(String mrNumber, String phone) async {
    _isLoading = true;
    notifyListeners();

    // Prepare phone number: normalize and add +92 suffix if needed
    String normalizedPhone = phone.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (normalizedPhone.isNotEmpty && !normalizedPhone.startsWith('+')) {
      if (!normalizedPhone.startsWith('92') && !normalizedPhone.startsWith('0')) {
        normalizedPhone = '+92$normalizedPhone';
      } else if (normalizedPhone.startsWith('0')) {
        normalizedPhone = '+92${normalizedPhone.substring(1)}';
      } else if (normalizedPhone.startsWith('92')) {
        normalizedPhone = '+92${normalizedPhone.substring(2)}';
      }
    }

    final result = await _authService.loginPatientPortal(
      PatientPortalLoginRequest(mrNumber: mrNumber.trim(), password: normalizedPhone),
    );

    if (result['success'] == true) {
      _token = result['token'];
      _currentUser = MobileUser.fromJson(result['user']);
      await _storageService.saveLoginData(
        token: _token!,
        userId: _currentUser!.id.toString(),
        username: _currentUser!.phone,
        fullName: _currentUser!.fullName,
        role: _currentUser!.role,
      );
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // ── Doctor & Appointment Methods ────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDoctors({String? department, String? search}) async {
    return await _authService.listDoctors(department: department, search: search);
  }

  Future<Map<String, dynamic>> fetchDepartments() async {
    return await _authService.listDepartments();
  }

  Future<Map<String, dynamic>> fetchSlots(String srlNo, String date) async {
    return await _authService.getDoctorSlots(srlNo, date, token: _token);
  }

  Future<void> fetchPortalSlots(int srlNo, String date) async {
    _isLoadingSlots = true;
    _portalSlots = [];
    _portalSlotsMessage = '';
    notifyListeners();

    final result = await _authService.getPatientPortalDoctorSlots(srlNo, date, token: _token);
    
    if (result['success'] == true) {
      final data = result['data'];
      _portalSlots = data['slots'] ?? [];
      _portalSlotsMessage = data['message'] ?? '';
    } else {
      _portalSlotsMessage = result['message'] ?? 'Failed to load slots';
    }

    _isLoadingSlots = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> bookPatientPortalAppointment(int srlNo, String date, String time) async {
    if (_token == null) return {'success': false, 'message': 'Not logged in'};
    
    _isLoading = true;
    notifyListeners();

    final result = await _authService.createPatientPortalAppointment(_token!, {
      'doctor_srl_no': srlNo,
      'appointment_date': date,
      'slot_time': time,
    });

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> book(String srlNo, String date, String time) async {
    if (_token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.bookAppointment(_token!, srlNo, date, time);
  }

  Future<Map<String, dynamic>> fetchMyAppointments() async {
    if (_token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.myAppointments(_token!);
  }

  // ── Doctor Dashboard Methods ──────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDoctorAppointments(String date) async {
    if (_token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.getDoctorAppointments(_token!, date);
  }

  Future<Map<String, dynamic>> fetchPatientRecord(String mrNumber) async {
    if (_token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.getPatientRecord(_token!, mrNumber);
  }

  Future<Map<String, dynamic>> finishAppointment(String id) async {
    final token = await _storageService.getToken();
    if (token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.completeAppointment(token, id);
  }

  Future<Map<String, dynamic>> cancelAppointment(String id) async {
    final token = await _storageService.getToken();
    if (token == null) return {'success': false, 'message': 'Not logged in'};
    return await _authService.cancelAppointment(token, id);
  }

  void logout() {
    _token = null;
    _currentUser = null;
    _otpSent = false;
    _storageService.clearAll();
    notifyListeners();
  }
}
