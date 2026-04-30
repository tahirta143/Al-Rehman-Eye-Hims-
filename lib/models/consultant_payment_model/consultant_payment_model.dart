class ConsultantPaymentAnalytics {
  final int totalDoctors;
  final double totalAmount;
  final double totalDoctorShare;
  final double totalHospitalRevenue;
  final int totalAppointments;
  final int totalRecords;

  ConsultantPaymentAnalytics({
    required this.totalDoctors,
    required this.totalAmount,
    required this.totalDoctorShare,
    required this.totalHospitalRevenue,
    required this.totalAppointments,
    required this.totalRecords,
  });

  factory ConsultantPaymentAnalytics.fromJson(Map<String, dynamic> json) {
    return ConsultantPaymentAnalytics(
      totalDoctors: json['doctors_count'] ?? json['total_doctors'] ?? 0,
      totalAmount: double.tryParse(json['total_services_amount']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
      totalDoctorShare: double.tryParse(json['total_doctor_share_amount']?.toString() ?? json['total_doctor_share']?.toString() ?? '0') ?? 0.0,
      totalHospitalRevenue: double.tryParse(json['hospital_revenue_amount']?.toString() ?? json['total_hospital_revenue']?.toString() ?? '0') ?? 0.0,
      totalAppointments: json['appointments_count'] ?? json['total_appointments'] ?? 0,
      totalRecords: json['records_count'] ?? 0,
    );
  }
}

class DoctorBreakdownModel {
  final String doctorId;
  final String doctorName;
  final String department;
  final int appointments;
  final double totalAmount;
  final double doctorShare;
  final double hospitalRevenue;
  final String status;

  DoctorBreakdownModel({
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.appointments,
    required this.totalAmount,
    required this.doctorShare,
    required this.hospitalRevenue,
    required this.status,
  });

  factory DoctorBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DoctorBreakdownModel(
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? '',
      department: json['payment_department'] ?? '',
      appointments: json['appointments_count'] ?? json['appointments'] ?? 0,
      totalAmount: double.tryParse(json['total_services_amount']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
      doctorShare: double.tryParse(json['total_doctor_share_amount']?.toString() ?? json['doctor_share']?.toString() ?? '0') ?? 0.0,
      hospitalRevenue: double.tryParse(json['hospital_revenue_amount']?.toString() ?? json['hospital_revenue']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Unpaid',
    );
  }
}

class PayoutRecordModel {
  final int srlNo;
  final String date;
  final String time;
  final String doctorName;
  final String patientName;
  final String patientId;
  final String serviceDetail;
  final double totalAmount;
  final double doctorShare;
  final double paymentShare;
  final String status;
  final String shareType; // percentage or fixed
  final bool opdCancelled;
  final bool shiftClosed;

  PayoutRecordModel({
    required this.srlNo,
    required this.date,
    required this.time,
    required this.doctorName,
    required this.patientName,
    required this.patientId,
    required this.serviceDetail,
    required this.totalAmount,
    required this.doctorShare,
    required this.paymentShare,
    required this.status,
    required this.shareType,
    required this.opdCancelled,
    required this.shiftClosed,
  });

  factory PayoutRecordModel.fromJson(Map<String, dynamic> json) {
    return PayoutRecordModel(
      srlNo: json['srl_no'] ?? 0,
      date: json['payment_date'] ?? json['date'] ?? '',
      time: json['payment_time'] ?? json['time'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      serviceDetail: json['patient_service'] ?? json['service_detail'] ?? '',
      totalAmount: double.tryParse(json['total']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
      doctorShare: double.tryParse(json['payment_amount']?.toString() ?? json['doctor_share']?.toString() ?? '0') ?? 0.0,
      paymentShare: double.tryParse(json['payment_share']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? '',
      shareType: json['share_type']?.toString() ?? (json['payment_share'] != null && double.parse(json['payment_share'].toString()) > 0 ? 'percentage' : 'fixed'),
      opdCancelled: (json['opd_cancelled'] == 1 || json['opd_cancelled'] == true),
      shiftClosed: (json['shift_closed'] == 1 || json['shift_closed'] == true),
    );
  }
}
