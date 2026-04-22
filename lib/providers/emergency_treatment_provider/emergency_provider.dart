import 'package:flutter/material.dart';

import '../../core/services/emergency_treatment_api_service.dart';
import '../../core/services/opd_receipt_api_service.dart';
import '../../core/services/mr_api_service.dart';
import '../../global/global_api.dart';
import '../../models/emergency_model/emergency_treatment_model.dart';
import '../../models/opd_model/opd_receipt_model.dart';

// ── Data Models ──

class EmergencyPatient {
  final String mrNo;
  final String name;
  final String age;
  final String gender;
  final String phone;
  final String address;
  final DateTime admittedSince;
  final String receiptNo;
  final List<String> emergencyServices;

  EmergencyPatient({
    required this.mrNo,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.admittedSince,
    this.receiptNo = '',
    this.emergencyServices = const [],
  });
}

class EmergencyService {
  final String id;
  final String name;
  final double price;
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const EmergencyService({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
    this.imageUrl,
  });
}

class EmergencyInvestigation {
  final String type;
  final String name;
  EmergencyInvestigation({required this.type, required this.name});
}

class EmergencyMedicine {
  final String name;
  final String dose;
  final String route;
  const EmergencyMedicine({required this.name, required this.dose, required this.route});
}

class EmergencyPrescription {
  final EmergencyMedicine medicine;
  EmergencyPrescription({required this.medicine});
}

// ── Provider ──

class EmergencyProvider extends ChangeNotifier {
  // ── Static MR formatter ──
  static String formatMr(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return int.parse(digits).toString().padLeft(5, '0');
  }

  // ── Queue (loaded from API) ──
  final List<EmergencyPatient> _queue = [];

  List<EmergencyPatient> get queue => List.unmodifiable(_queue);
  int get queueCount => _queue.length;

  bool _loadingQueue = false;
  bool get isLoadingQueue => _loadingQueue;

  final EmergencyTreatmentApiService _emergencyApi =
      EmergencyTreatmentApiService();

  /// Load the emergency queue from the API.
  Future<void> loadQueue() async {
    // Ensure we are not notifying during a build phase
    await Future.value();
    _loadingQueue = true;
    notifyListeners();
    final result = await _emergencyApi.fetchEmergencyQueue();
    if (result.success) {
      _queue
        ..clear()
        ..addAll(result.queue.map((item) => EmergencyPatient(
              mrNo: item.patientMrNumber,
              name: item.patientName,
              age: item.patientAge,
              gender: item.patientGender,
              phone: '',
              address: '',
              admittedSince: item.admittedSince != null
                  ? DateTime.tryParse(item.admittedSince!) ?? DateTime.now()
                  : DateTime.now(),
              emergencyServices: [],
            )));
    }
    _loadingQueue = false;
    notifyListeners();
  }

  // ── Emergency Services (loaded from API) ──
  final List<EmergencyService> _emergencyServices = [];
  List<EmergencyService> get emergencyServices => List.unmodifiable(_emergencyServices);

  bool _loadingServices = false;
  bool get isLoadingServices => _loadingServices;

  final OpdReceiptApiService _opdApi = OpdReceiptApiService();
  final MrApiService _mrApi = MrApiService();

  Future<MrPatientResult> fetchPatientInfoByMR(String mr) async {
    return await _mrApi.fetchPatientByMR(mr);
  }

  Future<OpdReceiptApiModel?> fetchLatestEmergencyReceipt(String mr) async {
    final res = await _opdApi.fetchOpdReceipts(mrNumber: mr, emergencyPaid: true);
    if (res.success && res.receipts.isNotEmpty) {
      return res.receipts.first;
    }
    return null;
  }

  Future<void> loadEmergencyServices() async {
    _loadingServices = true;
    notifyListeners();
    final result = await _opdApi.fetchOpdServices();
    if (result.success) {
      _emergencyServices.clear();
      for (final s in result.services) {
        if (s.isActive == 1 && s.allowEmergencyService != 0) {
          final rate = double.tryParse(s.serviceRate) ?? 0.0;
          
          // Map head to color/icon
          Color color = const Color(0xFFE53935);
          IconData icon = Icons.medical_services_rounded;
          
          switch (s.serviceHead.toLowerCase()) {
            case 'emergency': color = const Color(0xFFE53935); icon = Icons.emergency_rounded; break;
            case 'opd':       color = const Color(0xFF1E88E5); icon = Icons.local_hospital_rounded; break;
          }

          final imageUrl = GlobalApi.getImageUrl(s.imageUrl);

          _emergencyServices.add(EmergencyService(
            id: s.serviceId,
            name: s.serviceName,
            price: rate,
            icon: icon,
            color: color,
            imageUrl: imageUrl,
          ));
        }
      }
    }
    _loadingServices = false;
    notifyListeners();
  }

  /// Kept for backward compatibility with OPD receipt bridge (no-op now — queue comes from API).
  void addPatientFromOpd(Map<String, dynamic> data) {
    final mrNo = data['mrNo'] as String;
    // Don't add if already in queue
    if (_queue.any((p) => p.mrNo == mrNo)) return;

    _queue.add(EmergencyPatient(
      mrNo: mrNo,
      name: data['name'] ?? '',
      age: data['age'] ?? '',
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      admittedSince: data['admittedSince'] ?? DateTime.now(),
      receiptNo: data['receiptNo'] ?? '',
      emergencyServices: List<String>.from(data['emergencyServices'] ?? []),
    ));
    notifyListeners();
  }

  EmergencyPatient? lookupPatient(String mrNo) {
    try {
      return _queue.firstWhere((p) => p.mrNo == mrNo);
    } catch (_) {
      return null;
    }
  }

  void refresh() => notifyListeners();

  // ── Existing treatment record (loaded per-MR) ──
  EmergencyTreatmentApiModel? currentRecord;

  /// Fetch existing treatment for a given MR from the API.
  Future<EmergencyTreatmentApiModel?> fetchExistingTreatment(
      String mrNo) async {
    final result = await _emergencyApi.fetchByMR(mrNo);
    if (result.success) {
      currentRecord = result.record;
      return result.record;
    }
    return null;
  }

  /// Create a new treatment record.
  Future<EmergencyTreatmentResult> saveToApi(
      Map<String, dynamic> payload) async {
    return _emergencyApi.createTreatment(payload);
  }

  /// Update an existing treatment record.
  Future<EmergencyTreatmentResult> updateToApi(
      int id, Map<String, dynamic> payload) async {
    return _emergencyApi.updateTreatment(id, payload);
  }

  /// Create an emergency bill.
  Future<EmergencyBillingResult> createBill(
      Map<String, dynamic> payload) async {
    return _emergencyApi.createBill(payload);
  }

  /// Fetch current shift.
  Future<ShiftResult> fetchCurrentShift() async {
    return _emergencyApi.fetchCurrentShift();
  }


  // ── Selected emergency services ──
  final List<EmergencyService> _selectedServices = [];
  List<EmergencyService> get selectedServices => List.unmodifiable(_selectedServices);

  bool isServiceSelected(String id) => _selectedServices.any((s) => s.id == id);

  void toggleService(EmergencyService svc) {
    if (isServiceSelected(svc.id)) {
      _selectedServices.removeWhere((s) => s.id == svc.id);
    } else {
      _selectedServices.add(svc);
    }
    notifyListeners();
  }

  void removeSelectedService(String id) {
    _selectedServices.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  double get servicesTotalPrice =>
      _selectedServices.fold(0.0, (sum, s) => sum + s.price);

  // ── Investigations ──
  final Map<String, List<String>> investigations = const {
    'Lab': [
      'CBC (Complete Blood Count)',
      'LFTs (Liver Function Test)',
      'RFTs (Renal Function Test)',
      'Blood Sugar (Random)',
      'Blood Sugar (Fasting)',
      'HbA1c',
      'Lipid Profile',
      'Urine Analysis',
      'Blood Culture',
      'PT/APTT',
      'Serum Electrolytes',
    ],
    'Ultra Sound': [
      'Abdominal Ultrasound',
      'Pelvic Ultrasound',
      'Thyroid Ultrasound',
      'Cardiac Echo',
      'Renal Ultrasound',
    ],
    'X-Rays': [
      'Chest X-Ray',
      'Spine X-Ray',
      'Hand/Wrist X-Ray',
      'Skull X-Ray',
      'Pelvis X-Ray',
      'Knee X-Ray',
    ],
  };

  final List<EmergencyInvestigation> _addedInvestigations = [];
  List<EmergencyInvestigation> get addedInvestigations => List.unmodifiable(_addedInvestigations);

  void addInvestigation(String type, String name) {
    if (_addedInvestigations.any((i) => i.name == name)) {
      _addedInvestigations.removeWhere((i) => i.name == name);
    } else {
      _addedInvestigations.add(EmergencyInvestigation(type: type, name: name));
    }
    notifyListeners();
  }

  void removeInvestigation(String name) {
    _addedInvestigations.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  // ── Medicines ──
  final List<EmergencyMedicine> medicinesList = const [
    EmergencyMedicine(name: 'Paracetamol 500mg', dose: '1 tab', route: 'Oral'),
    EmergencyMedicine(name: 'Metoclopramide', dose: '10mg', route: 'IV'),
    EmergencyMedicine(name: 'Ondansetron', dose: '4mg', route: 'IV'),
    EmergencyMedicine(name: 'Diclofenac', dose: '75mg', route: 'IM'),
    EmergencyMedicine(name: 'Hydrocortisone', dose: '100mg', route: 'IV'),
    EmergencyMedicine(name: 'Salbutamol', dose: '2.5mg', route: 'Neb'),
    EmergencyMedicine(name: 'Ringer Lactate', dose: '1000ml', route: 'IV Drip'),
    EmergencyMedicine(name: 'Normal Saline', dose: '500ml', route: 'IV Drip'),
    EmergencyMedicine(name: 'Dextrose 5%', dose: '500ml', route: 'IV Drip'),
    EmergencyMedicine(name: 'Ceftriaxone', dose: '1g', route: 'IV'),
    EmergencyMedicine(name: 'Omeprazole', dose: '40mg', route: 'IV'),
    EmergencyMedicine(name: 'Tramadol', dose: '50mg', route: 'IM'),
  ];

  final List<EmergencyPrescription> _prescribedMedicines = [];
  List<EmergencyPrescription> get prescribedMedicines => List.unmodifiable(_prescribedMedicines);

  bool isMedicinePrescribed(String name) =>
      _prescribedMedicines.any((p) => p.medicine.name == name);

  void toggleMedicine(EmergencyMedicine med) {
    if (isMedicinePrescribed(med.name)) {
      _prescribedMedicines.removeWhere((p) => p.medicine.name == med.name);
    } else {
      _prescribedMedicines.add(EmergencyPrescription(medicine: med));
    }
    notifyListeners();
  }

  // ── Save record (local queue update only — API called from screen) ──
  void saveRecord({
    required String mrNo,
    required String name,
    required String age,
    required String gender,
    required String phone,
    required String address,
    required String mo,
    required String bed,
    required String complaint,
    required String moNotes,
    required String dischargeOpt,
    required List<EmergencyService> services,
    required List<EmergencyInvestigation> investigations,
    required List<EmergencyPrescription> medicines,
  }) {
    // On discharge — remove from queue
    if (dischargeOpt == 'After Treatment' ||
        dischargeOpt == 'Refer to Admission' ||
        dischargeOpt == 'Patient Expired') {
      _queue.removeWhere((p) => p.mrNo == mrNo);
    }
    notifyListeners();
  }

  void clearAll() {
    _selectedServices.clear();
    _addedInvestigations.clear();
    _prescribedMedicines.clear();
    currentRecord = null;
    notifyListeners();
  }

  /// Called on screen init — loads queue from real API.
  Future<void> refreshAll() async {
    await Future.wait([
      loadQueue(),
      loadEmergencyServices(),
    ]);
  }
}