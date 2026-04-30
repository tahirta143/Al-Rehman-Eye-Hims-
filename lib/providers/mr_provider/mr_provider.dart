import 'package:flutter/material.dart';
import '../../core/services/mr_api_service.dart';
import '../../models/mr_model/mr_patient_model.dart';

class MrProvider extends ChangeNotifier {
  final MrApiService _apiService = MrApiService();

  // ── Pagination State ──
  static const int _pageSize = 50;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  // ── Core State ──
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  String? _nextMrNumber;
  List<PatientModel> _patients = [];
  String _searchQuery = '';
  PatientModel? _selectedPatient;
  int _totalCount = 0;

  // ── Getters ──
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _currentPage <= _totalPages;
  String? get errorMessage => _errorMessage;
  String? get nextMrNumber => _nextMrNumber;
  PatientModel? get selectedPatient => _selectedPatient;
  int get totalPatients => _patients.length;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;

  // ── Constructor ──
  MrProvider() {
    loadPatients();
    fetchNextMR();
  }

  // ── Filtered patients list (local search fallback) ──
  List<PatientModel> get patients {
    if (_searchQuery.isEmpty) return List.from(_patients);
    final q = _searchQuery.toLowerCase();
    return _patients.where((p) {
      return p.mrNumber.toLowerCase().contains(q) ||
          p.fullName.toLowerCase().contains(q) ||
          p.phoneNumber.contains(q) ||
          p.cnic.contains(q);
    }).toList();
  }

  // ── Initial Load (page 1) ──
  Future<void> loadPatients() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _patients = [];
    _totalCount = 0;
    notifyListeners();

    final result = await _apiService.fetchAllPatients(
      page: 1,
      limit: _pageSize,
    );

    if (result.success) {
      _patients = result.patients.map((p) => p.toPatientModel()).toList();
      _totalPages = result.totalPages;
      _totalCount = result.count;
      _currentPage = 2;
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
      _patients = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Load Next Page ──
  Future<void> loadMorePatients() async {
    if (_isFetchingMore || !hasMorePages || _searchQuery.isNotEmpty) return;

    _isFetchingMore = true;
    notifyListeners();

    final result = await _apiService.fetchAllPatients(
      page: _currentPage,
      limit: _pageSize,
    );

    if (result.success) {
      _patients.addAll(result.patients.map((p) => p.toPatientModel()));
      _totalPages = result.totalPages;
      _totalCount = result.count;
      _currentPage++;
    } else {
      _errorMessage = result.message;
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  // ── Fetch Next MR Number ──
  Future<void> fetchNextMR() async {
    final result = await _apiService.fetchNextMRNumber();
    if (result.success && result.nextMR != null) {
      _nextMrNumber = result.nextMR;
      notifyListeners();
    }
  }

  // ── Live Search patients by name or phone ──
  Future<List<PatientModel>> searchPatients(String query) async {
    if (query.trim().length < 2) return [];

    final result = await _apiService.fetchAllPatients(
      page: 1,
      limit: 20,
      search: query.trim(),
    );

    if (result.success) {
      return result.patients.map((p) => p.toPatientModel()).toList();
    }
    return [];
  }

  // ── MR number lookup — always hits API to get full data with history ──
  Future<PatientModel?> findByMrNumber(String input, {bool normalize = false}) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final searchInput = normalize ? _normalizeMrNumber(trimmed) : trimmed;

    // ✅ Always fetch from API so we get visit history
    final result = await _apiService.fetchPatientByMR(searchInput);

    if (result.success && result.patient != null) {
      final patient = result.patient!.toPatientModel();

      // Update local cache
      final index =
      _patients.indexWhere((p) => p.mrNumber == patient.mrNumber);
      if (index != -1) {
        _patients[index] = patient;
      } else {
        _patients.insert(0, patient);
      }
      notifyListeners();
      return patient;
    }

    return null;
  }

  String _normalizeMrNumber(String input) {
    return input.trim();
  }

  // ── State mutations ──
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void selectPatient(PatientModel? patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  // ── Register new patient via API ──
  Future<PatientModel?> registerPatient({
    String mrNumber = '',
    required String firstName,
    required String lastName,
    String guardianName = '',
    String relation = 'Parent',
    required String gender,
    String dateOfBirth = '',
    int? age,
    String bloodGroup = '',
    String profession = '',
    String education = '',
    String whatsappNo = '',
    String phoneNumber = '',
    String email = '',
    String cnic = '',
    String address = '',
    String city = '',
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    final resolvedMr = mrNumber.trim().isEmpty
        ? (_nextMrNumber ?? '00001')
        : mrNumber.trim();

    final patient = PatientModel(
      mrNumber: resolvedMr,
      firstName: firstName.trim().toUpperCase(),
      lastName: lastName.trim().toUpperCase(),
      guardianName: guardianName.trim(),
      relation: relation,
      gender: gender,
      dateOfBirth: dateOfBirth,
      age: age,
      bloodGroup: bloodGroup,
      profession: profession,
      education: education,
      whatsappNo: whatsappNo,
      phoneNumber: phoneNumber.trim(),
      email: email.trim(),
      cnic: cnic.trim(),
      address: address.trim(),
      city: city.trim(),
      registeredAt: DateTime.now(),
    );

    final result = await _apiService.createPatient(patient.toApiRequest());
    _isCreating = false;

    if (result.success && result.patient != null) {
      final createdPatient = result.patient!.toPatientModel();
      _patients.insert(0, createdPatient);
      _totalCount++;
      _selectedPatient = createdPatient;
      _errorMessage = null;
      notifyListeners();
      fetchNextMR();
      return createdPatient;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return null;
    }
  }

  // ── Update existing patient via API ──
  Future<bool> updatePatient(PatientModel patient) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.updatePatient(
      patient.mrNumber,
      patient.toApiRequest(),
    );
    _isCreating = false;

    if (result.success && result.patient != null) {
      final updatedPatient = result.patient!.toPatientModel();
      final index =
      _patients.indexWhere((p) => p.mrNumber == patient.mrNumber);
      if (index != -1) _patients[index] = updatedPatient;
      if (_selectedPatient?.mrNumber == patient.mrNumber) {
        _selectedPatient = updatedPatient;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  // ── Delete patient via API ──
  Future<bool> deletePatient(String mrNumber) async {
    final result = await _apiService.deletePatient(mrNumber);
    if (result.success) {
      _patients.removeWhere((p) => p.mrNumber == mrNumber);
      _totalCount--;
      if (_selectedPatient?.mrNumber == mrNumber) _selectedPatient = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }
}