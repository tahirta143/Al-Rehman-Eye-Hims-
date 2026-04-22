import 'package:flutter/material.dart';

import '../../../core/services/opd_receipt_api_service.dart';
import '../../../core/services/consultation_api_service.dart';
import '../../../core/services/consultant_payments_api_service.dart';
import '../../../global/global_api.dart';
import '../../shift_management/shift_management.dart';
import '../../../models/consultation_model/doctor_model.dart';
import '../../../models/consultation_model/appointment_model.dart';


class OpdPatient {
  final String mrNo;
  final String fullName;
  final String phone;
  final String age;
  final String gender;
  final String address;
  final String city;
  final String panel;
  final String reference;

  const OpdPatient({
    required this.mrNo,
    required this.fullName,
    required this.phone,
    required this.age,
    required this.gender,
    required this.address,
    required this.city,
    required this.panel,
    required this.reference,
  });
}

class OpdService {
  final String id;
  final String name;
  final String category;
  final double price;
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const OpdService({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.icon,
    required this.color,
    this.imageUrl,
  });
}

class OpdSelectedService {
  final OpdService service;
  final int quantity;
  String? doctorName;
  String? doctorSpecialty;
  String? doctorAvatar;
  String? doctorDepartment;
  String? doctorSrlNo;

  OpdSelectedService({
    required this.service,
    this.quantity = 1,
    this.doctorName,
    this.doctorSpecialty,
    this.doctorAvatar,
    this.doctorDepartment,
    this.doctorSrlNo,
  });
}

class OpdProvider extends ChangeNotifier {
  final OpdReceiptApiService _apiService = OpdReceiptApiService();
  final ConsultantPaymentsApiService _paymentApiService =
  ConsultantPaymentsApiService();

  final ConsultationApiService _consultationApi = ConsultationApiService();

  List<DoctorModel> _availableDoctorModels = [];
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  bool _isLoadingAppointments = false;
  bool get isLoadingAppointments => _isLoadingAppointments;

  Map<String, dynamic>? _lastSavedReceiptTokens;
  Map<String, dynamic>? get lastSavedReceiptTokens => _lastSavedReceiptTokens;


  // ── Pagination State ──
  static const int _pageSize = 50;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _isFetchingMore = false;

  // ── Loading / error state ──
  bool _loadingServices = false;
  bool _loadingReceipts = false;
  bool _isDisposed = false; // ← CRASH FIX: track disposal
  String? _errorMessage;
  String? _lastSavedReceiptId;
  List<Map<String, dynamic>>? _lastSavedReceiptServices;
  double? _lastSavedReceiptTotal;
  double? _lastSavedReceiptDiscount;

  bool get isLoadingServices => _loadingServices;
  bool get isLoadingReceipts => _loadingReceipts;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMorePages => _currentPage <= _totalPages;
  int get totalReceiptsCount => _totalCount;
  String? get errorMessage => _errorMessage;
  String? get lastSavedReceiptId => _lastSavedReceiptId;
  List<Map<String, dynamic>>? get lastSavedReceiptServices => _lastSavedReceiptServices;
  double? get lastSavedReceiptTotal => _lastSavedReceiptTotal;
  double? get lastSavedReceiptDiscount => _lastSavedReceiptDiscount;
  bool _isLoading = false;
  bool _isSaving = false;

  // Add getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  // Add setters if needed (or use directly)
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  // ── Refer to Discount ──
  bool _isReferredToDiscount = false;
  bool get isReferredToDiscount => _isReferredToDiscount;
  void setReferredToDiscount(bool val) {
    _isReferredToDiscount = val;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CRASH FIX: Override dispose + safe notifyListeners
  // Root cause of crash: notifyListeners() called after widget disposed
  // while background async fetch was still running.
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ── Constructor ──
  OpdProvider() {
    _initStaticServices();
    // We no longer auto-load API data here to avoid unauthenticated 401 errors for patients.
    // Screens should call loadOpdServices(), loadDoctors(), and loadReceipts() explicitly.
  }

  // ── Mock Patients ──
  // final List<OpdPatient> _patients = const [
  //   OpdPatient(
  //       mrNo: '000001',
  //       fullName: 'Ahmed Hassan',
  //       phone: '0300-1234567',
  //       age: '35',
  //       gender: 'Male',
  //       address: '12-B Model Town',
  //       city: 'Lahore',
  //       panel: 'State Life',
  //       reference: 'General Physician'),
  //   OpdPatient(
  //       mrNo: '000002',
  //       fullName: 'Fatima Malik',
  //       phone: '0321-9876543',
  //       age: '28',
  //       gender: 'Female',
  //       address: 'House 5, Block C, Gulberg',
  //       city: 'Lahore',
  //       panel: 'EFU',
  //       reference: 'Specialist'),
  //   OpdPatient(
  //       mrNo: '000003',
  //       fullName: 'Muhammad Ali Khan',
  //       phone: '0333-5554444',
  //       age: '52',
  //       gender: 'Male',
  //       address: 'Sector G-10, Street 4',
  //       city: 'Islamabad',
  //       panel: 'SLIC',
  //       reference: 'General Physician'),
  //   OpdPatient(
  //       mrNo: '000004',
  //       fullName: 'Ayesha Siddiqui',
  //       phone: '0345-7778888',
  //       age: '41',
  //       gender: 'Female',
  //       address: 'Flat 3, Pearl Heights, Clifton',
  //       city: 'Karachi',
  //       panel: 'Jubilee',
  //       reference: 'Emergency'),
  //   OpdPatient(
  //       mrNo: '000005',
  //       fullName: 'Usman Tariq',
  //       phone: '0312-3334455',
  //       age: '19',
  //       gender: 'Male',
  //       address: 'Village Kot Addu',
  //       city: 'Muzaffargarh',
  //       panel: 'None',
  //       reference: 'General Physician'),
  // ];
  //
  // OpdPatient? lookupPatient(String mrNo) {
  //   try {
  //     return _patients.firstWhere((p) => p.mrNo == mrNo);
  //   } catch (_) {
  //     return null;
  //   }
  // }

  // ── Panels & References ──
  final List<String> panels = const [
    'None', 'State Life', 'EFU', 'SLIC',
    'Jubilee', 'Adamjee', 'New Hampshire', 'IGI',
  ];

  final List<String> references = const [
    'General Physician', 'Specialist', 'Emergency',
    'Self', 'Referral', 'Online',
  ];

  // ── OPD Service Categories ──
  final List<Map<String, dynamic>> serviceCategories = const [
    {'id': 'opd',          'label': 'OPD',          'icon': Icons.local_hospital_rounded,    'color': Color(0xFFE53935)},
    {'id': 'consultation', 'label': 'Consultation',  'icon': Icons.medical_information_rounded,'color': Color(0xFF00B5AD)},
    {'id': 'xray',         'label': 'X-Ray',         'icon': Icons.radio_rounded,             'color': Color(0xFF1E88E5)},
    {'id': 'ctscan',       'label': 'CT-Scan',       'icon': Icons.document_scanner_rounded,  'color': Color(0xFF8E24AA)},
    {'id': 'mri',          'label': 'MRI',           'icon': Icons.blur_circular_rounded,     'color': Color(0xFF00ACC1)},
    {'id': 'ultrasound',   'label': 'Ultrasound',    'icon': Icons.sensors_rounded,           'color': Color(0xFF43A047)},
    {'id': 'laboratory',   'label': 'Laboratory',    'icon': Icons.biotech_rounded,           'color': Color(0xFFF4511E)},
    {'id': 'emergency',    'label': 'Emergency',     'icon': Icons.emergency_rounded,         'color': Color(0xFFE53935)},
  ];

  // ── Services per Category ──
  final Map<String, List<OpdService>> services = {};

  void _initStaticServices() {
    services.clear();
    services.addAll({
      'consultation': [],
      'xray': [
        OpdService(id: 'xr1', name: 'Chest X-Ray',     category: 'xray', price: 800,  icon: Icons.radio_rounded, color: Color(0xFF1E88E5)),
        OpdService(id: 'xr2', name: 'Spine X-Ray',     category: 'xray', price: 1000, icon: Icons.radio_rounded, color: Color(0xFF1E88E5)),
        OpdService(id: 'xr3', name: 'Hand/Wrist X-Ray',category: 'xray', price: 600,  icon: Icons.radio_rounded, color: Color(0xFF1E88E5)),
      ],
      'ctscan': [
        OpdService(id: 'ct1', name: 'CT Head',    category: 'ctscan', price: 5000, icon: Icons.document_scanner_rounded, color: Color(0xFF8E24AA)),
        OpdService(id: 'ct2', name: 'CT Chest',   category: 'ctscan', price: 6000, icon: Icons.document_scanner_rounded, color: Color(0xFF8E24AA)),
        OpdService(id: 'ct3', name: 'CT Abdomen', category: 'ctscan', price: 7000, icon: Icons.document_scanner_rounded, color: Color(0xFF8E24AA)),
      ],
      'mri': [
        OpdService(id: 'mr1', name: 'MRI Brain', category: 'mri', price: 8000, icon: Icons.blur_circular_rounded, color: Color(0xFF00ACC1)),
        OpdService(id: 'mr2', name: 'MRI Spine', category: 'mri', price: 9000, icon: Icons.blur_circular_rounded, color: Color(0xFF00ACC1)),
        OpdService(id: 'mr3', name: 'MRI Knee',  category: 'mri', price: 7500, icon: Icons.blur_circular_rounded, color: Color(0xFF00ACC1)),
      ],
      'ultrasound': [
        OpdService(id: 'us1', name: 'Abdominal Ultrasound', category: 'ultrasound', price: 1500, icon: Icons.sensors_rounded, color: Color(0xFF43A047)),
        OpdService(id: 'us2', name: 'Pelvic Ultrasound',    category: 'ultrasound', price: 1500, icon: Icons.sensors_rounded, color: Color(0xFF43A047)),
        OpdService(id: 'us3', name: 'Thyroid Ultrasound',   category: 'ultrasound', price: 1200, icon: Icons.sensors_rounded, color: Color(0xFF43A047)),
      ],
      'laboratory': [
        OpdService(id: 'lb1', name: 'CBC (Complete Blood Count)', category: 'laboratory', price: 500,  icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb2', name: 'LFTs (Liver Function Test)', category: 'laboratory', price: 800,  icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb3', name: 'RFTs (Renal Function Test)', category: 'laboratory', price: 800,  icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb4', name: 'Blood Sugar (Fasting)',       category: 'laboratory', price: 200,  icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb5', name: 'HbA1c',                       category: 'laboratory', price: 1200, icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb6', name: 'Lipid Profile',               category: 'laboratory', price: 1000, icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
        OpdService(id: 'lb7', name: 'Urine Analysis',              category: 'laboratory', price: 300,  icon: Icons.biotech_rounded, color: Color(0xFFF4511E)),
      ],
      'emergency': [
        // OpdService(id: 'em1', name: 'Emergency Consultation', category: 'emergency', price: 2500, icon: Icons.emergency_rounded, color: Color(0xFFE53935)),
        // OpdService(id: 'em2', name: 'Trauma Care',            category: 'emergency', price: 5000, icon: Icons.emergency_rounded, color: Color(0xFFE53935)),
        // OpdService(id: 'em3', name: 'Resuscitation',          category: 'emergency', price: 3500, icon: Icons.emergency_rounded, color: Color(0xFFE53935)),
        // OpdService(id: 'em4', name: 'Emergency Surgery Prep', category: 'emergency', price: 4000, icon: Icons.emergency_rounded, color: Color(0xFFE53935)),
      ],
    });
  }

  // ── Load OPD Services from API ──
  Future<void> loadOpdServices() async {
    _loadingServices = true;
    _errorMessage = null;
    _safeNotify();

    try {
      // Parallelize API calls for better performance
      final results = await Future.wait([
        _apiService.fetchOpdServices(),
        _apiService.fetchLabTests(),
        _apiService.fetchRadiologyTests(),
      ]);

      final opdResult = results[0] as OpdServicesResult;
      final labResult = results[1] as Map<String, dynamic>;
      final radResult = results[2] as Map<String, dynamic>;

      if (_isDisposed) return; // CRASH FIX

      // Clear dynamic categories but keep consultation/emergency if needed
      services.removeWhere((key, _) => key != 'consultation' && key != 'emergency');

      // 1. Process OPD Services
      if (opdResult.success) {
        for (var s in opdResult.services) {
          if (s.isActive != 1) continue;

          final rate = double.tryParse(s.serviceRate) ?? 0.0;
          String category = 'opd';
          Color color = const Color(0xFFE53935);
          IconData icon = Icons.local_hospital_rounded;

          final head = s.serviceHead.toLowerCase();
          final name = s.serviceName.toLowerCase();

          // Categorize based on strings for standard OPD services
          if (head.contains('x-ray') || head.contains('xray') || name.contains('x-ray') || name.contains('xray')) {
            category = 'xray'; color = const Color(0xFF1E88E5); icon = Icons.radio_rounded;
          } else if (head.contains('ct scan') || head.contains('ctscan') || name.contains('ct scan') || name.contains('ctscan')) {
            category = 'ctscan'; color = const Color(0xFF8E24AA); icon = Icons.document_scanner_rounded;
          } else if (head.contains('mri') || name.contains('mri')) {
            category = 'mri'; color = const Color(0xFF00ACC1); icon = Icons.blur_circular_rounded;
          } else if (head.contains('ultrasound') || name.contains('ultrasound') || head.contains('u/s') || name.contains('u/s')) {
            category = 'ultrasound'; color = const Color(0xFF43A047); icon = Icons.sensors_rounded;
          } else if (head.contains('laboratory') || head.contains('lab') || name.contains('lab ') || name.contains(' laboratory')) {
            category = 'laboratory'; color = const Color(0xFFF4511E); icon = Icons.biotech_rounded;
          } else if (head.contains('emergency') || name.contains('emergency')) {
            category = 'emergency'; color = const Color(0xFFE53935); icon = Icons.emergency_rounded;
          }

          final imageUrl = s.imageUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint('🎯 Found image for OPD Service [${s.serviceName}]: $imageUrl');
          }

          final service = OpdService(
            id: s.serviceId, name: s.serviceName, category: category,
            price: rate, icon: icon, color: color, imageUrl: imageUrl,
          );

          if (!services.containsKey(category)) services[category] = [];
          if (!services[category]!.any((e) => e.id == service.id)) {
            services[category]!.add(service);
          }
        }
      }

      // 2. Process Lab Tests from Dedicated API
      if (labResult['success'] == true) {
        final list = labResult['data'] as List<dynamic>? ?? [];
        for (var t in list) {
          if (t['is_active'] == 0) continue;
          
          final service = OpdService(
            id: 'LB_${t['id'] ?? t['srl_no']}',
            name: t['test_name']?.toString() ?? 'Unnamed Lab Test',
            category: 'laboratory',
            price: double.tryParse(t['test_rate']?.toString() ?? '0') ?? 0.0,
            icon: Icons.biotech_rounded,
            color: const Color(0xFFF4511E),
            imageUrl: t['image_url']?.toString(),
          );
          
          if (!services.containsKey('laboratory')) services['laboratory'] = [];
          if (!services['laboratory']!.any((e) => e.id == service.id)) {
            services['laboratory']!.add(service);
          }
        }
      }

      // 3. Process Radiology Tests from Dedicated API
      if (radResult['success'] == true) {
        final list = radResult['data'] as List<dynamic>? ?? [];
        for (var t in list) {
          if (t['is_active'] == 0) continue;

          final testCatRaw = t['test_category']?.toString().toLowerCase() ?? '';
          String category = 'xray';
          Color color = const Color(0xFF1E88E5);
          IconData icon = Icons.radio_rounded;

          if (testCatRaw.contains('ct-scan') || testCatRaw.contains('ct scan')) {
            category = 'ctscan'; color = const Color(0xFF8E24AA); icon = Icons.document_scanner_rounded;
          } else if (testCatRaw.contains('mri')) {
            category = 'mri'; color = const Color(0xFF00ACC1); icon = Icons.blur_circular_rounded;
          } else if (testCatRaw.contains('ultrasound')) {
            category = 'ultrasound'; color = const Color(0xFF43A047); icon: Icons.sensors_rounded;
          }

          final service = OpdService(
            id: 'RD_${t['id'] ?? t['srl_no']}',
            name: t['test_name']?.toString() ?? 'Unnamed Rad Test',
            category: category,
            price: double.tryParse(t['test_rate']?.toString() ?? '0') ?? 0.0,
            icon: icon,
            color: color,
            imageUrl: t['image_url']?.toString(),
          );
          
          if (!services.containsKey(category)) services[category] = [];
          if (!services[category]!.any((e) => e.id == service.id)) {
            services[category]!.add(service);
          }
        }
      }

      _errorMessage = null;
    } catch (e) {
      if (!_isDisposed) _errorMessage = 'Failed to load services: $e';
      debugPrint('❌ Error loading OPD/Ref/Lab/Rad services: $e');
    }

    _loadingServices = false;
    _safeNotify();
  }

  // ── Load Doctors ──
  Future<void> loadDoctors() async {
    try {
      final result = await _consultationApi.fetchDoctors();

      if (_isDisposed) return; // CRASH FIX

      if (result.success && result.doctors.isNotEmpty) {
        final colors = [
          const Color(0xFF00B5AD), const Color(0xFF8E24AA),
          const Color(0xFF1E88E5), const Color(0xFFE53935),
          const Color(0xFF43A047), const Color(0xFFF4511E),
          const Color(0xFF00897B), const Color(0xFFD81B60),
        ];
        final doctorServices = result.doctors
            .where((d) => d.isActive == 1)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final i = entry.key;
          final d = entry.value;
          final fee = double.tryParse(d.consultationFee) ?? 0.0;
          final spec = d.doctorSpecialization.isNotEmpty ? ' (${d.doctorSpecialization})' : '';
          final imageUrl = d.imageUrl;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint('👨‍⚕️ Found image for Doctor [${d.doctorName}]: $imageUrl');
          }

          return OpdService(
            id: d.doctorId, name: 'Dr. ${d.doctorName}$spec',
            category: 'consultation', price: fee,
            icon: Icons.person_rounded, color: colors[i % colors.length],
            imageUrl: imageUrl,
          );
        }).toList();

        services['consultation'] = doctorServices;
        _availableDoctorModels = result.doctors;
        _safeNotify();
      }
    } catch (e) {
      debugPrint('❌ Error loading doctors: $e');
    }
  }

  // ── Fetch Upcoming Appointments ──
  Future<void> fetchUpcomingAppointments(String mrNumber) async {
    if (mrNumber.isEmpty) {
      _upcomingAppointments = [];
      _safeNotify();
      return;
    }
    _isLoadingAppointments = true;
    _safeNotify();
    try {
      final res = await _consultationApi.fetchAppointmentsByMr(mrNumber);
      if (res.success) {
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        _upcomingAppointments = res.appointments.where((a) {
          final aDate = a.appointmentDate?.split('T')[0];
          return aDate == todayStr && a.status?.toLowerCase() != 'cancelled';
        }).toList();
      } else {
        _upcomingAppointments = [];
      }
    } catch (e) {
      _upcomingAppointments = [];
      debugPrint('Error fetching appointments: $e');
    } finally {
      _isLoadingAppointments = false;
      _safeNotify();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RECEIPTS — Paginated loading
  // ─────────────────────────────────────────────────────────────────────────────

  // Internal mutable list — do NOT expose directly to UI widgets
  final List<Map<String, dynamic>> _receipts = [];

  // Read-only copy for UI — safe to iterate
  List<Map<String, dynamic>> get receipts => List.unmodifiable(_receipts);

  // ── Convert API model → local map (shared helper) ──
  Map<String, dynamic> _toReceiptMap(dynamic r) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(r.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return {
      'srl_no': r.srlNo,
      'receipt_id': r.receiptId,
      'receiptNo': r.receiptId,
      'mrNo': r.patientMrNumber,
      'patient_mr_number': r.patientMrNumber,
      'patient_name': r.patientName,
      'patientName': r.patientName,
      'age': r.patientAge?.toString() ?? '',
      'patient_age': r.patientAge,
      'gender': r.patientGender,
      'patient_gender': r.patientGender,
      'date': parsedDate,
      'shift_date': parsedDate,
      'services': r.serviceDetail.isNotEmpty
          ? r.serviceDetail.split(',').map((e) => e.trim()).toList()
          : (r.opdService.isNotEmpty
          ? r.opdService.split(',').map((e) => e.trim()).toList()
          : <String>[]),
      'details': r.serviceDetail,
      'service_detail': r.serviceDetail,
      'total': r.totalAmount,
      'total_amount': r.totalAmount,
      'discount': r.discount,
      'paid': r.paid,
      'payable': r.payable ?? (r.totalAmount - r.discount),
      'status': r.status,
      'opd_cancelled': r.opdCancelled ?? false,
      'paid_to_doctor': r.paidToDoctor ?? false,
      'phone_number': r.phoneNumber,
    };
  }

  // ── Load page 1 (called on init and refresh) ──
  Future<void> loadReceipts() async {
    if (_isDisposed) return;

    _loadingReceipts = true;
    _errorMessage = null;
    _currentPage = 1;
    _receipts.clear();
    _totalCount = 0;
    _safeNotify();

    try {
      final result = await _apiService.fetchOpdReceipts(page: 1, limit: _pageSize);

      if (_isDisposed) return; // CRASH FIX: widget might be gone by now

      if (result.success) {
        _receipts.addAll(result.receipts.map(_toReceiptMap));
        _totalPages = result.totalPages;
        _totalCount = result.totalCount;
        _currentPage = 2; // next page to fetch
        _errorMessage = null;
      } else {
        _errorMessage = result.message;
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to load receipts: $e';
        debugPrint('❌ Error loading receipts: $e');
      }
    }

    _loadingReceipts = false;
    _safeNotify();
  }

  // ── Load next page (called by scroll listener) ──
  Future<void> loadMoreReceipts() async {
    if (_isDisposed || _isFetchingMore || !hasMorePages) return;

    _isFetchingMore = true;
    _safeNotify();

    try {
      final result = await _apiService.fetchOpdReceipts(
        page: _currentPage,
        limit: _pageSize,
      );

      if (_isDisposed) return; // CRASH FIX

      if (result.success) {
        _receipts.addAll(result.receipts.map(_toReceiptMap));
        _totalPages = result.totalPages;
        _totalCount = result.totalCount;
        _currentPage++;
      } else {
        _errorMessage = result.message;
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint('❌ Error loading more receipts: $e');
      }
    }

    _isFetchingMore = false;
    _safeNotify();
  }

  // ── Cancel receipt ──
  Future<bool> cancelReceipt(int index, String cancelReason) async {
    if (index < 0 || index >= _receipts.length) return false;

    final receipt = _receipts[index];
    final receiptSrlNo = receipt['srl_no'];

    if (receiptSrlNo == null || receiptSrlNo == 0) {
      _errorMessage = 'Cannot cancel: Missing receipt serial number';
      _safeNotify();
      return false;
    }

    _loadingReceipts = true;
    _errorMessage = null;
    _safeNotify();

    final result = await _apiService.cancelOpdReceipt(receiptSrlNo, cancelReason);

    if (_isDisposed) return result.success; // CRASH FIX

    if (result.success) {
      _receipts[index]['status'] = 'Cancelled';
      _receipts[index]['details'] = 'CANCELLED - ${_receipts[index]['details']}';
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _loadingReceipts = false;
    _safeNotify();
    return result.success;
  }

  // ── Refund receipt ──
  Future<bool> refundReceipt(int index, double refundAmount, String refundReason) async {
    if (index < 0 || index >= _receipts.length) return false;

    final receipt = _receipts[index];
    debugPrint('💰 Attempting to refund receipt at index $index: $receipt');

    int? receiptSrlNo;
    if (receipt.containsKey('srl_no') && receipt['srl_no'] != null) {
      receiptSrlNo = receipt['srl_no'] is int
          ? receipt['srl_no'] as int
          : int.tryParse(receipt['srl_no'].toString());
    }

    if (receiptSrlNo == null || receiptSrlNo == 0) {
      _errorMessage = 'Cannot refund: Missing receipt serial number. Please refresh data.';
      debugPrint('❌ ERROR: Missing srl_no in receipt: $receipt');
      _safeNotify();
      return false;
    }

    _loadingReceipts = true;
    _errorMessage = null;
    _safeNotify();

    final result = await _apiService.refundOpdReceipt(receiptSrlNo, refundAmount, refundReason);

    if (_isDisposed) return result.success; // CRASH FIX

    if (result.success) {
      _receipts[index]['status'] = 'Refunded';
      _receipts[index]['discount'] = (receipt['discount'] as double) + refundAmount;
      _receipts[index]['paid'] = (receipt['paid'] as double) - refundAmount;

      if (result.receipt != null) {
        _receipts[index]['total_amount'] = result.receipt!.totalAmount;
        _receipts[index]['discount'] = result.receipt!.discount;
        _receipts[index]['paid'] = result.receipt!.paid;
        _receipts[index]['payable'] = result.receipt!.payable;
      }

      debugPrint('✅ Refund successful for receipt srl_no: $receiptSrlNo');
      _errorMessage = null;
    } else {
      debugPrint('❌ Refund failed: ${result.message}');
      _errorMessage = result.message;
    }

    _loadingReceipts = false;
    _safeNotify();
    return result.success;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SELECTED SERVICES
  // ─────────────────────────────────────────────────────────────────────────────

  final List<OpdSelectedService> _selectedServices = [];
  List<OpdSelectedService> get selectedServices => List.unmodifiable(_selectedServices);

  void addService(OpdService service) {
    if (!_selectedServices.any((s) => s.service.id == service.id)) {
      String? dept, srl, dName;

      if (service.category == 'consultation') {
        try {
          final doc = _availableDoctorModels.firstWhere(
                (d) => d.doctorId == service.id,
            orElse: () => _availableDoctorModels.firstWhere(
                  (d) => 'Dr. ${d.doctorName}' == service.name.split(' (')[0],
              orElse: () => _availableDoctorModels.first,
            ),
          );
          dept = doc.doctorDepartment;
          srl = doc.srlNo.toString();
          dName = doc.doctorName;
        } catch (_) {}
      }

      _selectedServices.add(OpdSelectedService(
        service: service,
        doctorName: dName,
        doctorDepartment: dept,
        doctorSrlNo: srl,
      ));
      _safeNotify();
    }
  }

  void removeService(String serviceId) {
    _selectedServices.removeWhere((s) => s.service.id == serviceId);
    _safeNotify();
  }

  bool isSelected(String serviceId) =>
      _selectedServices.any((s) => s.service.id == serviceId);

  double get servicesTotal =>
      _selectedServices.fold(0.0, (sum, s) => sum + (s.service.price * s.quantity));

  void clearServices() {
    _selectedServices.clear();
    _safeNotify();
  }

  bool get hasEmergencyService =>
      _selectedServices.any((s) => s.service.category == 'emergency');

  bool _emergencyAdmission = false;
  bool get emergencyAdmission => _emergencyAdmission;
  set emergencyAdmission(bool val) {
    _emergencyAdmission = val;
    _safeNotify();
  }

  final List<Map<String, dynamic>> _admittedEmergencyPatients = [];
  List<Map<String, dynamic>> get admittedEmergencyPatients =>
      List.unmodifiable(_admittedEmergencyPatients);

  void admitEmergencyPatient(Map<String, dynamic> patientData) {
    _admittedEmergencyPatients.add(patientData);
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SAVE RECEIPT
  // ─────────────────────────────────────────────────────────────────────────────

  int _receiptCounter = 71960;

  Future<bool> saveReceipt({
    required OpdPatient patient,
    required List<OpdSelectedService> services,
    required double discount,
    required double amountPaid,
    ShiftModel? currentShift,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final double totalAmount = services.fold(0.0, (sum, s) => sum + (s.service.price * s.quantity));
    final double payableAmount = (totalAmount - discount).clamp(0.0, double.infinity);
    final double balanceAmount = (payableAmount - amountPaid).clamp(0.0, double.infinity);

    // --- Token Flow Sync (React Parity) ---
    final Map<String, dynamic> appointmentTokens = {};
    final List<int> appointmentIds = [];

    for (var svc in services) {
      if (svc.service.category == 'consultation' &&
          svc.doctorSrlNo != null &&
          svc.doctorSrlNo!.isNotEmpty) {
        // Try to find matching appointment in today's upcoming appointments
        try {
          final matchingAppt = _upcomingAppointments.firstWhere((a) {
            final drId = a.doctorSrlNo.toString();
            final patientMr = a.mrNumber;
            // Parity Fix: Compare against doctorSrlNo, not service.id
            return drId == svc.doctorSrlNo && patientMr == patient.mrNo;
          });

          if (matchingAppt.tokenNumber != null) {
            appointmentTokens[svc.doctorSrlNo!] = matchingAppt.tokenNumber;
          }
          appointmentIds.add(matchingAppt.id);
        } catch (_) {
          // No match found in upcoming appointments
        }
      }
    }

    // Map category keys to display labels matching React's OPDReceipt.jsx logic
    String _categoryToLabel(String category, OpdSelectedService svc) {
      switch (category) {
        case 'consultation': return 'Consultation';
        case 'laboratory':   return 'Laboratory';
        case 'xray':         return 'X-Ray';
        case 'ctscan':       return 'CT-Scan';
        case 'mri':          return 'MRI';
        case 'ultrasound':   return 'Ultrasound';
        case 'emergency':    return 'Emergency';
        default:            return svc.service.name;
      }
    }

    final servicesHeads = services.map((s) => _categoryToLabel(s.service.category, s)).toSet().toList();
    // React prefixes consultation details with "Dr. Name"
    final detailsList = services.map((s) {
      if (s.service.category == 'consultation' && s.doctorName != null && s.doctorName!.isNotEmpty) {
        return 'Dr. ${s.doctorName}';
      }
      return s.service.name;
    }).toList();

    String? firstDoctorId;
    final consSvc = services.where((s) => s.service.category == 'consultation').toList();
    if (consSvc.isNotEmpty) firstDoctorId = consSvc.first.service.id;

    double avgDrShare = consSvc.isNotEmpty ? 100.0 : 0;
    double totalDrShare = 0;

    final serviceDetails = services.map((s) {
      double drShare = 0;
      final lineTotal = s.service.price * s.quantity;
      if (s.service.category == 'consultation') drShare = lineTotal;
      totalDrShare += drShare;
      return {
        'id': s.service.id, 'name': s.service.name,
        'rate': s.service.price, 'quantity': s.quantity, 'total': lineTotal,
        'type': s.service.category, 'drShare': drShare > 0 ? 100 : 0,
        'doctorSrlNo': s.doctorSrlNo,
        'doctorName': s.doctorName,
        'department': s.doctorDepartment,
      };
    }).toList();

    final payload = {
      'patient_mr_number': patient.mrNo,
      'patient_name': patient.fullName,
      'phone_number': patient.phone.isEmpty ? 'N/A' : patient.phone,
      'patient_age': patient.age,
      'patient_gender': patient.gender,
      'patient_address': patient.address.isEmpty ? 'N/A' : patient.address,
      'city': patient.city.isEmpty ? 'N/A' : patient.city,
      'panel': (patient.panel == 'None' || patient.panel.isEmpty) ? 'Private' : patient.panel,
      'reference': (patient.reference == 'None' || patient.reference.isEmpty) ? 'Self' : patient.reference,
      'doctor_id': firstDoctorId,
      'date': dateStr, 'time': timeStr,
      'opd_service': servicesHeads.join(', '),
      'service_detail': detailsList.join(', '),
      'service_details': serviceDetails,
      'total_amount': totalAmount, 'service_amount': totalAmount,
      'discount': discount, 'payable': payableAmount,
      'paid': amountPaid, 'balance': balanceAmount,
      'dr_share': avgDrShare, 'dr_share_amount': totalDrShare,
      'hospital_share': totalAmount - totalDrShare,
      'opd_discount': discount > 0, 'discount_amount': discount,
      'discount_reason': null, 'discount_id': null,
      'patient_token_appointment': appointmentIds.isNotEmpty,
      'appointment_tokens': appointmentTokens,
      'appointment_ids': appointmentIds,
      'patient_checked': false,
      'patient_requested_discount': discount > 0,
      'status': 'Active', 'payment_mode': 'Cash', 'receipt_type': 'Small',
      'shift_id': currentShift?.shiftId ?? 0,
      'shift_type': currentShift?.shiftType ?? 'N/A',
      'shift_date': currentShift?.shiftDate ?? dateStr,
      'emergency_paid': servicesHeads.any((h) => h.toLowerCase() == 'emergency'),
      'refer_to_discount': _isReferredToDiscount,
    };

    debugPrint('══ OPD RECEIPT PAYLOAD ══\n$payload');

    final apiResult = await _apiService.createOpdReceipt(payload);

    debugPrint('══ OPD RECEIPT RESULT ══\nsuccess: ${apiResult.success}\nmessage: ${apiResult.message}');

    if (_isDisposed) return apiResult.success;

    if (!apiResult.success) {
      _errorMessage = apiResult.message;
      _safeNotify();
      return false;
    }

    _lastSavedReceiptId = apiResult.receipt?.receiptId;
    _lastSavedReceiptTokens = apiResult.tokens ?? apiResult.receipt?.tokens;
    _lastSavedReceiptServices = List<Map<String, dynamic>>.from(serviceDetails);
    _lastSavedReceiptTotal = totalAmount;
    _lastSavedReceiptDiscount = discount;

    // Post-save cleanup logic removed (MR incrementing handled by MrProvider + UI)

    // Consultant payment records
    if (!_isReferredToDiscount) {
      for (var svc in services) {
      double drShareAmount = svc.service.category == 'consultation' ? svc.service.price : 0;
      if (drShareAmount > 0) {
        final dName = svc.doctorName ??
            (services.firstWhere((s) => s.doctorName != null, orElse: () => services.first).doctorName ?? 'Unknown');
        final dDept = svc.doctorDepartment ?? '';

        await _paymentApiService.createConsultantPayment({
          'payment_date': dateStr, 'payment_time': timeStr,
          'doctor_name': dName, 'payment_department': dDept,
          'total': svc.service.price, 'payment_share': 100,
          'payment_amount': drShareAmount,
          'patient_id': patient.mrNo, 'patient_date': dateStr,
          'patient_service': svc.service.name, 'patient_name': patient.fullName,
          'shift_id': currentShift?.shiftId ?? 0,
          'shift_type': currentShift?.shiftType ?? 'N/A',
          'shift_date': currentShift?.shiftDate ?? dateStr,
        });
      }
    }
  }

    if (_isDisposed) return true;

    final receiptNo = apiResult.receipt?.receiptId ?? 'OPD$_receiptCounter';

    _receipts.insert(0, {
      'receiptNo': receiptNo,
      'mrNo': patient.mrNo, 'patientName': patient.fullName,
      'age': patient.age, 'gender': patient.gender,
      'date': DateTime.now(),
      'services': services.map((s) => s.service.name).toList(),
      'details': detailsList.join(', '),
      'total': totalAmount, 'discount': discount,
      'paid': amountPaid, 'status': 'Active',
    });
    _receiptCounter++;
    _totalCount++;

    if (_emergencyAdmission &&
        services.any((s) => s.service.category == 'emergency')) {
      _admittedEmergencyPatients.add({
        'mrNo': patient.mrNo, 'name': patient.fullName,
        'age': patient.age, 'gender': patient.gender,
        'phone': patient.phone, 'address': patient.address,
        'admittedSince': DateTime.now(), 'receiptNo': receiptNo,
        'emergencyServices': services
            .where((s) => s.service.category == 'emergency')
            .map((s) => s.service.name)
            .toList(),
      });
    }

    _emergencyAdmission = false;
    _selectedServices.clear();
    _safeNotify();
    return true;
  }
}