import 'package:flutter/material.dart';
import '../../core/services/prescription_api_service.dart';
import '../../core/services/mr_api_service.dart';
import '../../core/services/vitals_api_service.dart';
import '../../models/mr_model/mr_patient_model.dart';
import '../../models/prescription_model/prescription_model.dart';
import '../../models/vitals_model/vitals_model.dart';

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionApiService _apiService = PrescriptionApiService();
  final MrApiService _mrApiService = MrApiService();
  final VitalsApiService _vitalsApiService = VitalsApiService();

  // ─── Loading States ───────────────────────────────────────────────
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingPatients = false;
  bool _isLoadingHistory = false;
  bool _isLoadingTests = false;
  String? _errorMessage;

  // New Alignment State
  String? _receiptId;
  String? _tokenNumber;
  String? _doctorName;
  int? _doctorSrlNo;
  String _medMode = 'medicine'; // 'medicine' or 'formula'
  String _inputLang = 'en'; // 'en' or 'ur'
  List<dynamic> _medicineSearchResults = [];
  String _medSearchQuery = '';
  
  // Investigation Search
  String _labSearch = '';
  String _xraySearch = '';
  String _ultrasoundSearch = '';
  String _ctSearch = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingPatients => _isLoadingPatients;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingTests => _isLoadingTests;
  String? get errorMessage => _errorMessage;

  String? get receiptId => _receiptId;
  String? get tokenNumber => _tokenNumber;
  String? get doctorName => _doctorName;
  int? get doctorSrlNo => _doctorSrlNo;
  String get medMode => _medMode;
  String get inputLang => _inputLang;
  List<dynamic> get medicineSearchResults => _medicineSearchResults;
  String get medSearchQuery => _medSearchQuery;
  String get labSearch => _labSearch;
  String get xraySearch => _xraySearch;
  String get ultrasoundSearch => _ultrasoundSearch;
  String get ctSearch => _ctSearch;

  bool get isAdmissionReferral => noteControllers['referTo']!.text.trim().toLowerCase().contains('admission');

  // ─── Patient State ────────────────────────────────────────────────
  PatientModel? _currentPatient;
  PatientModel? get currentPatient => _currentPatient;

  VitalsModel? _currentVitals;
  VitalsModel? get currentVitals => _currentVitals;

  List<dynamic> _consultationPatients = [];
  List<dynamic> get consultationPatients => _consultationPatients;

  List<dynamic> _prescriptionHistory = [];
  List<dynamic> get prescriptionHistory => _prescriptionHistory;

  // ─── Tests State ──────────────────────────────────────────────────
  List<dynamic> _labTests = [];
  List<dynamic> _radiologyTests = [];
  List<dynamic> get labTests => _labTests;
  List<dynamic> get radiologyTests => _radiologyTests;


  // ─── Form Data (Common) ───────────────────────────────────────────
  final Map<String, TextEditingController> vitalControllers = {
    'temp': TextEditingController(),
    'bp': TextEditingController(),
    'pulse': TextEditingController(),
    'weight': TextEditingController(),
    'height': TextEditingController(),
    'blood': TextEditingController(),
  };

  final Map<String, TextEditingController> noteControllers = {
    'history': TextEditingController(),
    'treatment': TextEditingController(),
    'notes': TextEditingController(),
    'remarks': TextEditingController(),
    'referTo': TextEditingController(),
  };

  // ─── GP Specific State ────────────────────────────────────────────
  List<PrescriptionMedicine> _prescribedMedicines = [];
  List<PrescriptionMedicine> get prescribedMedicines => _prescribedMedicines;

  List<PrescriptionInvestigation> _selectedInvestigations = [];
  List<PrescriptionInvestigation> get selectedInvestigations => _selectedInvestigations;

  List<String> _instructions = [];
  List<String> get instructions => _instructions;

  List<dynamic> _diagnosisQuestions = [];
  List<dynamic> get diagnosisQuestions => _diagnosisQuestions;
  
  Map<int, dynamic> _diagnosisAnswers = {};
  Map<int, dynamic> get diagnosisAnswers => _diagnosisAnswers;

  // ─── Eye Specific State ───────────────────────────────────────────
  // History Checkboxes
  final Map<String, bool> eyeHistory = {
    'Asthma': false, 'Diabetes': false, 'HBV': false, 'HCV': false,
    'Hypertension': false, 'Ischemic Heart Disease': false, 'Pregnancy': false, 'RT Injury': false,
  };
  final TextEditingController eyeOtherHistoryCtrl = TextEditingController();

  // Refraction Matrix
  final Map<String, Map<String, TextEditingController>> refractionCtrls = {
    'right': {
      'sph': TextEditingController(), 'cyl': TextEditingController(), 
      'axis': TextEditingController(), 'va': TextEditingController(), 'addition': TextEditingController()
    },
    'left': {
      'sph': TextEditingController(), 'cyl': TextEditingController(), 
      'axis': TextEditingController(), 'va': TextEditingController(), 'addition': TextEditingController()
    },
    'add': {
      'sph': TextEditingController(), 'cyl': TextEditingController(), 
      'axis': TextEditingController(), 'va': TextEditingController(), 'addition': TextEditingController()
    },
  };

  // Vision Stats
  final Map<String, Map<String, TextEditingController>> visionCtrls = {
    'right': {'var': TextEditingController(), 'ph': TextEditingController(), 'ref': TextEditingController()},
    'left': {'var': TextEditingController(), 'ph': TextEditingController(), 'ref': TextEditingController()},
  };

  // Examination & Management
  final TextEditingController presentingComplaintsCtrl = TextEditingController();
  List<EyeSideItem> _eyeComplaints = [];
  List<EyeSideItem> _eyeExaminations = [];
  List<EyeSideItem> _eyeAdvised = [];
  String _eyeTreatmentType = '';
  final TextEditingController eyeRemarksCtrl = TextEditingController();
  DateTime? _eyeOperationDate;

  List<EyeSideItem> get eyeComplaints => _eyeComplaints;
  List<EyeSideItem> get eyeExaminations => _eyeExaminations;
  List<EyeSideItem> get eyeAdvised => _eyeAdvised;
  String get eyeTreatmentType => _eyeTreatmentType;
  DateTime? get eyeOperationDate => _eyeOperationDate;

  // ─── Actions ─────────────────────────────────────────────────────

  Future<void> loadConsultationPatients() async {
    _isLoadingPatients = true;
    notifyListeners();
    final res = await _apiService.fetchConsultationPatients();
    if (res['success'] == true) {
      _consultationPatients = res['data'] ?? [];
    }
    _isLoadingPatients = false;
    notifyListeners();
  }

  Future<void> selectConsultationPatient(dynamic patient, {String? department}) async {
    final mr = patient['patient_mr_number']?.toString() ?? '';
    final paddedMr = mr.padLeft(5, '0');
    _receiptId = patient['receipt_id']?.toString();
    _tokenNumber = patient['token_number']?.toString();
    _doctorSrlNo = int.tryParse(patient['doctor_srl_no']?.toString() ?? '');
    _doctorName = patient['doctor_name']?.toString();
    
    // Update vitality check or similar if needed
    vitalControllers['receiptId']?.text = _receiptId ?? '';

    await searchPatient(paddedMr, department: department);
  }

  void setMedMode(String mode) {
    _medMode = mode;
    _medicineSearchResults = [];
    _medSearchQuery = '';
    notifyListeners();
  }

  void setInputLang(String lang) {
    _inputLang = lang;
    notifyListeners();
  }

  void updateLabSearch(String q) { _labSearch = q; notifyListeners(); }
  void updateXraySearch(String q) { _xraySearch = q; notifyListeners(); }
  void updateUltrasoundSearch(String q) { _ultrasoundSearch = q; notifyListeners(); }
  void updateCtSearch(String q) { _ctSearch = q; notifyListeners(); }

  void updateMedSearch(String query) async {
    _medSearchQuery = query;
    if (query.isEmpty) {
      _medicineSearchResults = [];
      notifyListeners();
      return;
    }
    
    final res = await _apiService.searchMedicines(query);
    if (res['success'] == true) {
      _medicineSearchResults = res['data'] ?? [];
    }
    notifyListeners();
  }

  Future<void> searchPatient(String mrNumber, {String? department}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPatient = null;
    notifyListeners();

    // Pad MR number to 5 digits (Align with React)
    final paddedMr = mrNumber.padLeft(5, '0');

    final result = await _mrApiService.fetchPatientByMR(paddedMr);
    if (result.success && result.patient != null) {
      _currentPatient = result.patient!.toPatientModel();
      await fetchDiagnosis(department ?? 'General'); 
      await fetchVitals(paddedMr, receiptId: _receiptId);
      await fetchHistory(paddedMr);
    } else {
      _errorMessage = result.message ?? 'Patient not found';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchVitals(String mrNumber, {String? receiptId}) async {
    _currentVitals = null;
    notifyListeners();
    try {
      Map<String, dynamic> res = {'success': false};

      // 1. Try fetching by Receipt ID first if available
      if (receiptId != null && receiptId.isNotEmpty) {
        res = await _vitalsApiService.getVitalsByReceipt(receiptId);
      }

      // 2. Fallback to MR Number if Receipt fetch failed or returned no data
      if (res['success'] != true || res['data'] == null) {
        res = await _vitalsApiService.getVitalsByMR(mrNumber);
      }
      
      if (res['success'] == true && res['data'] != null) {
        _currentVitals = VitalsModel.fromJson(res['data']);
      }
    } catch (e) {
      debugPrint('Error fetching vitals: $e');
    }
    notifyListeners();
  }

  Future<void> fetchHistory(String mrNumber) async {
    _isLoadingHistory = true;
    notifyListeners();
    final res = await _apiService.fetchPrescriptionHistory(mrNumber);
    if (res['success'] == true) {
      _prescriptionHistory = res['data'] ?? [];
    }
    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadTests() async {
    if (_labTests.isNotEmpty && _radiologyTests.isNotEmpty) return;
    _isLoadingTests = true;
    notifyListeners();
    
    final labRes = await _apiService.fetchLabTests();
    if (labRes['success'] == true) _labTests = labRes['data'] ?? [];

    final radRes = await _apiService.fetchRadiologyTests();
    if (radRes['success'] == true) _radiologyTests = radRes['data'] ?? [];

    _isLoadingTests = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> searchMedicines(String query) async {
    return await _apiService.searchMedicines(query);
  }

  Future<void> fetchDiagnosis(String department) async {
    final res = await _apiService.fetchDiagnosisQuestions(department);
    if (res['success'] == true) {
      _diagnosisQuestions = res['data'] ?? [];
      _diagnosisAnswers = {};
    }
    notifyListeners();
  }

  // ─── GP Form Helpers ──────────────────────────────────────────────
  
  void addMedicine(PrescriptionMedicine med) {
    _prescribedMedicines.add(med);
    notifyListeners();
  }

  void removeMedicine(int index) {
    _prescribedMedicines.removeAt(index);
    notifyListeners();
  }

  void toggleInvestigation(String type, String name) {
    final exists = _selectedInvestigations.any((i) => i.investigationType == type && i.testName == name);
    if (exists) {
      _selectedInvestigations.removeWhere((i) => i.investigationType == type && i.testName == name);
    } else {
      _selectedInvestigations.add(PrescriptionInvestigation(investigationType: type, testName: name));
    }
    notifyListeners();
  }

  void addInstruction(String text) {
    if (text.trim().isNotEmpty) {
      _instructions.add(text.trim());
      notifyListeners();
    }
  }

  void removeInstruction(int index) {
    _instructions.removeAt(index);
    notifyListeners();
  }

  void setDiagnosisAnswer(int questionId, dynamic value) {
    _diagnosisAnswers[questionId] = value;
    notifyListeners();
  }

  void setAdmissionReferral(bool value) {
    final controller = noteControllers['referTo']!;
    if (value) {
      if (controller.text.trim().isEmpty || controller.text.trim().toLowerCase() != 'admission') {
        controller.text = 'Admission';
      }
    } else {
      if (controller.text.trim().toLowerCase() == 'admission') {
        controller.text = '';
      }
    }
    notifyListeners();
  }

  // ─── Eye Form Helpers ───────────────────────────────────────────

  void toggleEyeHistory(String key) {
    eyeHistory[key] = !(eyeHistory[key] ?? false);
    notifyListeners();
  }

  void addEyeItem(String listType, String name, String side) {
    final item = EyeSideItem(name: name, side: side);
    if (listType == 'complaint') _eyeComplaints.add(item);
    else if (listType == 'examination') _eyeExaminations.add(item);
    else if (listType == 'advised') _eyeAdvised.add(item);
    notifyListeners();
  }

  void removeEyeItem(String listType, int index) {
    if (listType == 'complaint') _eyeComplaints.removeAt(index);
    else if (listType == 'examination') _eyeExaminations.removeAt(index);
    else if (listType == 'advised') _eyeAdvised.removeAt(index);
    notifyListeners();
  }

  void setEyeTreatmentType(String type) {
    _eyeTreatmentType = type;
    notifyListeners();
  }

  void setOperationDate(DateTime date) {
    _eyeOperationDate = date;
    notifyListeners();
  }

  // ─── Submission ──────────────────────────────────────────────────

  Future<bool> savePrescription({bool isEye = false, required String doctorName, int? doctorSrlNo}) async {
    if (_currentPatient == null) return false;
    
    _isSaving = true;
    notifyListeners();

    final vitals = {
      for (var entry in vitalControllers.entries) entry.key: entry.value.text
    };

    final prescription = PrescriptionModel(
      mrNumber: _currentPatient!.mrNumber,
      doctorName: _doctorName ?? doctorName,
      doctorSrlNo: _doctorSrlNo ?? (doctorSrlNo ?? 1),
      vitals: vitals,
      receiptId: _receiptId,
      historyExamination: noteControllers['history']!.text,
      treatment: noteControllers['treatment']!.text,
      consultantNotes: noteControllers['notes']!.text,
      remarks: noteControllers['remarks']!.text,
      referTo: noteControllers['referTo']!.text,
      medicines: _prescribedMedicines,
      investigations: _selectedInvestigations,
      instructions: _instructions,
      diagnosis: _diagnosisAnswers.entries.map((e) => PrescriptionDiagnosis(
        questionId: e.key,
        questionText: '', 
        answerText: e.value is String ? e.value : null,
        answerValue: e.value,
      )).toList(),
      eyeDetails: isEye ? _buildEyeDetails() : null,
    );

    final res = await _apiService.savePrescription(prescription.toJson());
    
    _isSaving = false;
    notifyListeners();

    return res['success'] == true;
  }

  EyePrescriptionDetails _buildEyeDetails() {
    return EyePrescriptionDetails(
      history: Map<String, bool>.from(eyeHistory),
      otherHistory: eyeOtherHistoryCtrl.text,
      rightRefraction: _getRefraction('right'),
      leftRefraction: _getRefraction('left'),
      addRefraction: _getRefraction('add'),
      rightVision: _getVision('right'),
      leftVision: _getVision('left'),
      presentingComplaints: presentingComplaintsCtrl.text,
      complaints: _eyeComplaints,
      examinations: _eyeExaminations,
      advised: _eyeAdvised,
      treatmentType: _eyeTreatmentType,
      remarks: eyeRemarksCtrl.text,
      operationDate: _eyeOperationDate?.toIso8601String(),
    );
  }

  RefractionMatrix _getRefraction(String side) {
    final ctrls = refractionCtrls[side]!;
    return RefractionMatrix(
      sph: ctrls['sph']!.text,
      cyl: ctrls['cyl']!.text,
      axis: ctrls['axis']!.text,
      va: ctrls['va']!.text,
      addition: ctrls['addition']!.text,
    );
  }

  VisionStats _getVision(String side) {
    final ctrls = visionCtrls[side]!;
    return VisionStats(
      varValue: ctrls['var']!.text,
      ph: ctrls['ph']!.text,
      ref: ctrls['ref']!.text,
    );
  }

  void clearForm() {
    for (var c in vitalControllers.values) c.clear();
    for (var c in noteControllers.values) c.clear();
    _prescribedMedicines = [];
    _selectedInvestigations = [];
    _instructions = [];
    _diagnosisAnswers = {};
    _currentPatient = null;
    _receiptId = null;
    _tokenNumber = null;
    _doctorName = null;
    _doctorSrlNo = null;
    _medMode = 'medicine';
    _medicineSearchResults = [];
    _medSearchQuery = '';
    notifyListeners();
  }
}
