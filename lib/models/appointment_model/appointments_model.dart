import '../consultation_model/appointment_model.dart' as appt_model;

class AppointmentModel {
  final int id;
  final String appointmentId;
  final String mrNumber;
  final String patientName;
  final String patientContact;
  final String? patientAddress;
  final int doctorSrlNo;
  final String appointmentDate;
  final String slotTime;
  final bool isFirstVisit;
  final double fee;
  final double followUpCharges;
  final String status;
  final String createdAt;
  final String doctorName;
  final String doctorSpecialization;
  final String consultationTimeFrom;
  final String consultationTimeTo;
  final int? tokenNumber;

  AppointmentModel({
    required this.id,
    required this.appointmentId,
    required this.mrNumber,
    required this.patientName,
    required this.patientContact,
    this.patientAddress,
    required this.doctorSrlNo,
    required this.appointmentDate,
    required this.slotTime,
    required this.isFirstVisit,
    required this.fee,
    required this.followUpCharges,
    required this.status,
    required this.createdAt,
    required this.doctorName,
    required this.doctorSpecialization,
    required this.consultationTimeFrom,
    required this.consultationTimeTo,
    this.tokenNumber,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      appointmentId: json['appointment_id'] ?? '',
      mrNumber: json['mr_number'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientContact: json['patient_contact'] ?? '',
      patientAddress: json['patient_address'],
      doctorSrlNo: json['doctor_srl_no'] ?? 0,
      appointmentDate: json['appointment_date'] ?? '',
      slotTime: json['slot_time'] ?? '',
      isFirstVisit: (json['is_first_visit'] ?? 0) == 1,
      fee: double.tryParse(json['fee']?.toString() ?? '0') ?? 0.0,
      followUpCharges:
      double.tryParse(json['follow_up_charges']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialization: json['doctor_specialization'] ?? '',
      consultationTimeFrom: json['consultation_time_from'] ?? '',
      consultationTimeTo: json['consultation_time_to'] ?? '',
      tokenNumber: int.tryParse(json['token_number']?.toString() ?? ''),
    );
  }

  /// e.g. "2:30 PM"
  String get formattedSlotTime {
    try {
      final parts = slotTime.split(':');
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $ampm';
    } catch (_) {
      return slotTime;
    }
  }

  /// e.g. "02 Mar 2026"
  String get formattedDate {
    try {
      final parts = appointmentDate.split('-');
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = months[int.parse(parts[1])];
      return '${parts[2]} $month ${parts[0]}';
    } catch (_) {
      return appointmentDate;
    }
  }

  /// Formatted fee e.g. "PKR 4,000.00"
  String get formattedFee {
    final amount = isFirstVisit ? fee : followUpCharges;
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return 'PKR $formatted';
  }

  /// Used for stats revenue — always use fee for first visit, followUp otherwise
  double get effectiveFee => isFirstVisit ? fee : followUpCharges;

  String get visitType => isFirstVisit ? 'First' : 'Follow-up';

  String get statusDisplay =>
      status.isNotEmpty ? '${status[0].toUpperCase()}${status.substring(1)}' : '';

  /// Today's date string YYYY-MM-DD
  static String get todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Convert to ConsultationAppointment for UI compatibility
  appt_model.ConsultationAppointment toConsultationAppointment(String hospitalName) {
    // Parse date
    final date = DateTime.parse(appointmentDate);

    return appt_model.ConsultationAppointment(
      id: id.toString(),
      consultantName: 'Dr. $doctorName',
      specialty: doctorSpecialization,
      consultationFee: fee.toString(),
      followUpCharges: followUpCharges.toString(),
      availableDays: [],
      timings: '$consultationTimeFrom - $consultationTimeTo',
      hospital: hospitalName,
      mrNo: mrNumber,
      patientName: patientName,
      contactNo: patientContact,
      address: patientAddress ?? '',
      isFirstVisit: isFirstVisit,
      appointmentDate: date,
      timeSlot: formattedSlotTime,
      type: 'In-Person',
      status: status,
      tokenNumber: tokenNumber,
    );
  }
}