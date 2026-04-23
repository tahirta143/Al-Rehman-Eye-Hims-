import 'package:flutter/material.dart';
import '../../core/services/mr_api_service.dart';
import '../../core/services/prescription_api_service.dart';
import '../../core/services/vitals_api_service.dart';
import '../../models/mr_model/mr_patient_model.dart';
import '../../models/vitals_model/vitals_model.dart';

class VitalsProvider extends ChangeNotifier {
  final VitalsApiService _apiService = VitalsApiService();
  final MrApiService _mrApiService = MrApiService();
  final PrescriptionApiService _prescriptionApiService = PrescriptionApiService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingConsultations = false;
  String? _errorMessage;
  PatientModel? _currentPatient;
  String? _receiptId;
  String? _tokenNumber;
  String? _doctorName;

  List<dynamic> _consultationPatients = [];
  
  // Controllers
  final Map<String, TextEditingController> controllers = {
    'weight': TextEditingController(),
    'height': TextEditingController(),
    'bsr': TextEditingController(),
    'systolic': TextEditingController(),
    'diastolic': TextEditingController(),
    'pulse': TextEditingController(),
    'spo2': TextEditingController(),
    'temperature': TextEditingController(),
    'waist': TextEditingController(),
    'hip': TextEditingController(),
  };

  // Computed Values
  String _bmi = '—';
  String _bmr = '—';
  String _whr = '—';
  int _painScale = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingConsultations => _isLoadingConsultations;
  String? get errorMessage => _errorMessage;
  PatientModel? get currentPatient => _currentPatient;
  String? get receiptId => _receiptId;
  String? get tokenNumber => _tokenNumber;
  String? get doctorName => _doctorName;
  List<dynamic> get consultationPatients => _consultationPatients;
  
  String get bmi => _bmi;
  String get bmr => _bmr;
  String get whr => _whr;
  int get painScale => _painScale;

  VitalsProvider() {
    // Add listeners for real-time calculations
    controllers['weight']!.addListener(_calculateBmiAndBmr);
    controllers['height']!.addListener(_calculateBmiAndBmr);
    controllers['waist']!.addListener(_calculateWhr);
    controllers['hip']!.addListener(_calculateWhr);
  }

  @override
  void dispose() {
    for (var ctrl in controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ─── Patient Search ──────────────────────────────────────────────────
  Future<void> searchPatient(String mrNumber, {String? customReceiptId, String? customDoctor, String? tokenNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPatient = null;
    _receiptId = customReceiptId;
    _tokenNumber = tokenNumber;
    _doctorName = customDoctor;
    notifyListeners();

    final mr = mrNumber.trim();

    try {
      final res = await _mrApiService.fetchPatientByMR(mr);
      if (res.success && res.patient != null) {
        _currentPatient = res.patient!.toPatientModel();
        await _fetchVitalsHistory(mr, customReceiptId);
      } else {
        _errorMessage = res.message ?? 'Patient not found';
      }
    } catch (e) {
      _errorMessage = 'Error searching patient: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      _calculateBmiAndBmr(); // Re-calculate BMR when patient data changes
    }
  }

  Future<void> _fetchVitalsHistory(String mrNumber, String? rId) async {
    try {
      Map<String, dynamic> res = {'success': false};

      // 1. Try by Receipt ID first
      if (rId != null && rId.isNotEmpty) {
        res = await _apiService.getVitalsByReceipt(rId);
      }

      // 2. Fallback to MR Number if Receipt fetch failed
      if (res['success'] != true || res['data'] == null) {
        res = await _apiService.getVitalsByMR(mrNumber);
      }
      
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        _fillControllers(data);
      } else {
        _clearInputs();
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  void _fillControllers(Map<String, dynamic> data) {
    controllers['weight']!.text = (data['weight'] ?? '').toString();
    controllers['height']!.text = (data['height'] ?? '').toString();
    controllers['bsr']!.text = (data['bsr'] ?? '').toString();
    controllers['systolic']!.text = (data['systolic'] ?? '').toString();
    controllers['diastolic']!.text = (data['diastolic'] ?? '').toString();
    controllers['pulse']!.text = (data['pulse'] ?? '').toString();
    controllers['spo2']!.text = (data['spo2'] ?? '').toString();
    controllers['temperature']!.text = (data['temperature'] ?? '').toString();
    controllers['waist']!.text = (data['waist'] ?? '').toString();
    controllers['hip']!.text = (data['hip'] ?? '').toString();
    _painScale = (data['pain_scale'] as num?)?.toInt() ?? 0;
    notifyListeners();
  }

  void _clearInputs() {
    for (var ctrl in controllers.values) {
      ctrl.clear();
    }
    _painScale = 0;
    notifyListeners();
  }

  // ─── Calculations ───────────────────────────────────────────────────
  void _calculateBmiAndBmr() {
    final w = double.tryParse(controllers['weight']!.text) ?? 0;
    final hInches = double.tryParse(controllers['height']!.text) ?? 0;
    final hMeters = hInches * 0.0254;
    final hCm = hInches * 2.54;

    // BMI
    if (w > 0 && hMeters > 0) {
      _bmi = (w / (hMeters * hMeters)).toStringAsFixed(1);
    } else {
      _bmi = '—';
    }

    // BMR (Mifflin-St Jeor)
    if (w > 0 && hCm > 0 && _currentPatient != null) {
      final age = _currentPatient!.age ?? 30;
      final isMale = _currentPatient!.gender.toLowerCase().startsWith('m');
      if (isMale) {
        _bmr = ((10 * w) + (6.25 * hCm) - (5 * age) + 5).toStringAsFixed(0);
      } else {
        _bmr = ((10 * w) + (6.25 * hCm) - (5 * age) - 161).toStringAsFixed(0);
      }
    } else {
      _bmr = '—';
    }
    notifyListeners();
  }

  void _calculateWhr() {
    final waist = double.tryParse(controllers['waist']!.text) ?? 0;
    final hip = double.tryParse(controllers['hip']!.text) ?? 0;
    if (waist > 0 && hip > 0) {
      _whr = (waist / hip).toStringAsFixed(3);
    } else {
      _whr = '—';
    }
    notifyListeners();
  }

  void setPainScale(int val) {
    _painScale = val;
    notifyListeners();
  }

  // ─── Consultation Patients ─────────────────────────────────────────
  Future<void> fetchConsultationPatients() async {
    _isLoadingConsultations = true;
    notifyListeners();
    try {
      final res = await _prescriptionApiService.fetchConsultationPatients();
      if (res['success'] == true) {
        final List list = res['data'] ?? [];
        // Filter out Eye department fixed in plans
        _consultationPatients = list.where((cp) {
          final dept = cp['doctor_department']?.toString().toLowerCase() ?? '';
          return !dept.contains('eye');
        }).toList();
      }
    } catch (e) {
      debugPrint('Error consultations: $e');
    } finally {
      _isLoadingConsultations = false;
      notifyListeners();
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────
  Future<bool> saveVitals() async {
    if (_currentPatient == null) return false;
    _isSaving = true;
    notifyListeners();

    try {
      final model = VitalsModel(
        mrNumber: _currentPatient!.mrNumber,
        receiptId: _receiptId,
        weight: double.tryParse(controllers['weight']!.text),
        height: double.tryParse(controllers['height']!.text),
        bsr: double.tryParse(controllers['bsr']!.text),
        bmi: double.tryParse(_bmi),
        bmr: double.tryParse(_bmr),
        systolic: int.tryParse(controllers['systolic']!.text),
        diastolic: int.tryParse(controllers['diastolic']!.text),
        pulse: int.tryParse(controllers['pulse']!.text),
        spo2: double.tryParse(controllers['spo2']!.text),
        temperature: double.tryParse(controllers['temperature']!.text),
        waist: double.tryParse(controllers['waist']!.text),
        hip: double.tryParse(controllers['hip']!.text),
        whr: double.tryParse(_whr),
        painScale: _painScale,
      );

      final res = await _apiService.saveVitals(model.toJson());
      return res['success'] == true;
    } catch (e) {
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
