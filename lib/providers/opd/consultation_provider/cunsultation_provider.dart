import 'package:flutter/material.dart';
import '../../../core/services/consultation_api_service.dart';
import '../../../models/consultation_model/doctor_model.dart';
import '../../../models/consultation_model/appointment_model.dart';

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────
class ConsultationProvider extends ChangeNotifier {
  final ConsultationApiService _apiService = ConsultationApiService();

  // ── State ──
  bool _isLoading = false;
  bool _isLoadingAppointments = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  bool get isLoadingAppointments => _isLoadingAppointments;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  // ── Doctors ──
  List<DoctorInfo> _doctors = [];
  List<DoctorInfo> get doctors => _doctors;

  // ── Constructor: Load data on init ──
  ConsultationProvider() {
    // We no longer auto-load here to avoid unauthenticated 401 errors at startup.
    // Screens should call loadDoctors and loadAppointments explicitly in initState.
  }

  // ── Load Doctors from API ──
  Future<void> loadDoctors({bool isPublic = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.fetchDoctors(isPublic: isPublic);

    if (result.success) {
      // Convert DoctorModel to DoctorInfo
      _doctors = result.doctors.map((doctor) {
        // Count appointments for this doctor (only if we have appointments loaded)
        final appointmentCount = _appointments
            .where((a) => a.consultantName == 'Dr. ${doctor.doctorName}')
            .length;
        return doctor.toDoctorInfo(totalAppointments: appointmentCount);
      }).toList();
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
      _doctors = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetLoading() {
    _isLoading = true;
    notifyListeners();
  }

  // ── Appointments ──
  List<ConsultationAppointment> _appointments = [];

  List<ConsultationAppointment> get appointments =>
      List.unmodifiable(_appointments);

  List<Map<String, dynamic>> get appointmentsAsMaps =>
      _appointments.map((a) => a.toMap()).toList();

  // ── Load Appointments from API ──
  Future<void> loadAppointments({bool isPublic = false}) async {
    _isLoadingAppointments = true;
    notifyListeners();

    final result = await _apiService.fetchAppointments(isPublic: isPublic);

    if (result.success) {
      // Convert AppointmentModel to ConsultationAppointment
      _appointments = result.appointments.map((appointment) {
        // Find hospital name from doctor
        final doctor = _doctors.firstWhere(
          (d) => d.id == appointment.doctorSrlNo.toString(),
          orElse: () => DoctorInfo(
            id: '',
            name: '',
            specialty: '',
            consultationFee: '',
            followUpCharges: '',
            availableDays: [],
            timings: '',
            hospital: 'WMCTH',
            imageAsset: '',
            department: '',
            avatarColor: Colors.grey,
            totalAppointments: 0,
          ),
        );
        return appointment.toConsultationAppointment(doctor.hospital);
      }).toList();
    } else {
      _appointments = [];
    }

    _isLoadingAppointments = false;
    notifyListeners();
  }

  // ── Patient History ──
  List<ConsultationAppointment> _patientHistory = [];
  List<ConsultationAppointment> get patientHistory => _patientHistory;

  Future<void> fetchPatientHistory(String mrNumber) async {
    _isLoadingHistory = true;
    _patientHistory = [];
    notifyListeners();

    final result = await _apiService.fetchAppointmentsByMr(mrNumber);

    if (result.success) {
      _patientHistory = result.appointments.map((appointment) {
        final doctor = _doctors.firstWhere(
          (d) => d.id == appointment.doctorSrlNo.toString(),
          orElse: () => DoctorInfo(
            id: '',
            name: '',
            specialty: '',
            consultationFee: '',
            followUpCharges: '',
            availableDays: [],
            timings: '',
            hospital: 'WMCTH',
            imageAsset: '',
            department: '',
            avatarColor: Colors.grey,
            totalAppointments: 0,
          ),
        );
        return appointment.toConsultationAppointment(doctor.hospital);
      }).toList();
    }
    _isLoadingHistory = false;
    notifyListeners();
  }

  // ── Summary stats ──
  int get totalConsultations => _appointments.length;
  int get upcomingAppointments =>
      _appointments.where((a) => a.status == 'Upcoming').length;
  int get completedAppointments =>
      _appointments.where((a) => a.status == 'Completed').length;

  // ── Appointments for a specific doctor on a specific date ──
  List<ConsultationAppointment> appointmentsForDoctorOnDate(
      String doctorName, DateTime date) {
    return _appointments
        .where((a) =>
    a.consultantName == doctorName &&
        a.appointmentDate.year == date.year &&
        a.appointmentDate.month == date.month &&
        a.appointmentDate.day == date.day &&
        a.status != 'Cancelled')
        .toList();
  }

  // ── Available slots for doctor ──
  int availableSlotsForDoctor(String doctorName, DateTime date) {
    final doctor = doctors.firstWhere(
          (d) => d.name == doctorName,
      orElse: () => doctors.first,
    );
    final allSlots = generateTimeSlots(doctor.timings);
    final booked = bookedSlots(date, doctorName);
    return allSlots.length - booked.length;
  }

  // ── Consultants map list (for backward compat) ──
  List<Map<String, dynamic>> get consultants => doctors.map((d) => {
    'name': d.name,
    'specialty': d.specialty,
    'fee': d.consultationFee,
    'followUp': d.followUpCharges,
    'days': d.availableDays,
    'timings': d.timings,
    'hospital': d.hospital,
  }).toList();

  // ── ADD Appointment (POST to API) ──
  Future<bool> addAppointment(ConsultationAppointment appointment) async {
    // Find doctor srl_no from doctor name
    final doctorName = appointment.consultantName.replaceAll('Dr. ', '');
    final doctor = _doctors.firstWhere(
      (d) => d.name.contains(doctorName),
      orElse: () => _doctors.first,
    );

    final doctorSrlNo = int.tryParse(doctor.id) ?? 0;

    // Convert to API request format
    final requestData = appointment.toApiRequest(doctorSrlNo);

    // Call API
    final result = await _apiService.createAppointment(requestData);

    if (result.success) {
      // Add to local list
      _appointments.insert(0, appointment);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  // ── DELETE / CANCEL ──
  Future<bool> cancelAppointment(String id) async {
    final appointmentId = int.tryParse(id);
    if (appointmentId == null) return false;

    final result = await _apiService.deleteAppointment(appointmentId);
    if (result.success) {
      _appointments.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  // ── UPDATE ──
  Future<bool> updateAppointment(String id, ConsultationAppointment appointment) async {
    final appointmentId = int.tryParse(id);
    if (appointmentId == null) return false;

    // Find doctor srl_no
    final doctorName = appointment.consultantName.replaceAll('Dr. ', '');
    final doctor = _doctors.firstWhere(
      (d) => d.name.contains(doctorName),
      orElse: () => _doctors.first,
    );
    final doctorSrlNo = int.tryParse(doctor.id) ?? 0;

    final requestData = appointment.toApiRequest(doctorSrlNo);
    final result = await _apiService.updateAppointment(appointmentId, requestData);

    if (result.success) {
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = appointment;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.message;
      notifyListeners();
      return false;
    }
  }

  void removeAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ── Time slot helpers ──
  List<String> generateTimeSlots(String timings) {
    try {
      final parts = timings.split(' - ');
      if (parts.length != 2) return [];
      final start = _parseTime(parts[0].trim());
      final end = _parseTime(parts[1].trim());
      if (start == null || end == null) return [];
      final slots = <String>[];
      var current = start;
      while (_timeToMinutes(current) < _timeToMinutes(end)) {
        slots.add(_formatTime(current));
        current = _addMinutes(current, 15);
      }
      return slots;
    } catch (_) {
      return [];
    }
  }

  List<String> bookedSlots(DateTime date, String consultantName) {
    return _appointments
        .where((a) =>
    a.consultantName == consultantName &&
        a.appointmentDate.year == date.year &&
        a.appointmentDate.month == date.month &&
        a.appointmentDate.day == date.day &&
        a.status != 'Cancelled')
        .map((a) => a.timeSlot)
        .toList();
  }

  TimeOfDay? _parseTime(String s) {
    try {
      final isPM = s.contains('PM');
      final isAM = s.contains('AM');
      final cleaned = s.replaceAll('AM', '').replaceAll('PM', '').trim();
      final p = cleaned.split(':');
      int hour = int.parse(p[0]);
      int minute = int.parse(p[1]);
      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  TimeOfDay _addMinutes(TimeOfDay t, int m) {
    final total = _timeToMinutes(t) + m;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  String _formatTime(TimeOfDay t) {
    int hour = t.hour % 12;
    if (hour == 0) hour = 12;

    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }
}