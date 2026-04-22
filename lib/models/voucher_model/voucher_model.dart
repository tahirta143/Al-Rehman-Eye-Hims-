// voucher_model.dart
// Pure model/entity classes for Discount Voucher Approval

import 'dart:convert';

class ServiceItem {
  final int srNo;
  final String service;
  final String type;
  final double rate;
  final int qty;

  const ServiceItem({
    required this.srNo,
    required this.service,
    required this.type,
    required this.rate,
    required this.qty,
  });

  double get total => rate * qty;

  ServiceItem copyWith({
    int? srNo,
    String? service,
    String? type,
    double? rate,
    int? qty,
  }) {
    return ServiceItem(
      srNo: srNo ?? this.srNo,
      service: service ?? this.service,
      type: type ?? this.type,
      rate: rate ?? this.rate,
      qty: qty ?? this.qty,
    );
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json, int index) {
    return ServiceItem(
      srNo: index + 1,
      service: json['name'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? json['head'] as String? ?? '',
      rate: double.tryParse(json['rate']?.toString() ?? '0') ?? 0.0,
      qty: int.tryParse(json['qty']?.toString() ?? '1') ?? 1,
    );
  }
}

class VoucherDetail {
  final int srlNo;
  final String invoiceId;
  final String date;
  final String time;
  final String patientName;
  final String age;
  final String gender;
  final String phone;
  final String address;
  final String patientMrNumber;
  final List<ServiceItem> services;
  final double discountAmountValue;
  final double totalAmount;
  final double payableAmt;
  final String discountReason;
  final String opdService;
  final VoucherStatus status;

  const VoucherDetail({
    required this.srlNo,
    required this.invoiceId,
    required this.date,
    required this.time,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.phone,
    required this.address,
    required this.patientMrNumber,
    required this.services,
    required this.discountAmountValue,
    required this.totalAmount,
    required this.payableAmt,
    required this.discountReason,
    required this.opdService,
    this.status = VoucherStatus.pending,
  });

  double get total => totalAmount;
  double get discountAmount => discountAmountValue;
  double get payable => payableAmt;
  double get discountPercentage => total > 0 ? (discountAmount / total) * 100 : 0.0;

  VoucherDetail copyWith({
    VoucherStatus? status,
  }) {
    return VoucherDetail(
      srlNo: srlNo,
      invoiceId: invoiceId,
      date: date,
      time: time,
      patientName: patientName,
      age: age,
      gender: gender,
      phone: phone,
      address: address,
      patientMrNumber: patientMrNumber,
      services: services,
      discountAmountValue: discountAmountValue,
      totalAmount: totalAmount,
      payableAmt: payableAmt,
      discountReason: discountReason,
      opdService: opdService,
      status: status ?? this.status,
    );
  }

  factory VoucherDetail.fromJson(Map<String, dynamic> json) {
    List<ServiceItem> parsedServices = [];
    final svDetails = json['service_details'];
    if (svDetails != null) {
      try {
        List<dynamic> list;
        if (svDetails is String) {
          list = jsonDecode(svDetails);
        } else if (svDetails is List) {
          list = svDetails;
        } else {
          list = [];
        }
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic>) {
            parsedServices.add(ServiceItem.fromJson(item, i));
          }
        }
      } catch (_) {}
    }

    return VoucherDetail(
      srlNo: json['srl_no'] ?? 0,
      invoiceId: json['receipt_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? '',
      age: json['patient_age']?.toString() ?? '',
      gender: json['patient_gender']?.toString() ?? '',
      phone: json['phone_number']?.toString() ?? '',
      address: json['patient_address']?.toString() ?? '',
      patientMrNumber: json['patient_mr_number']?.toString() ?? '',
      services: parsedServices,
      discountAmountValue: double.tryParse(json['discount_amount']?.toString() ?? json['discount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      payableAmt: double.tryParse(json['payable']?.toString() ?? '0') ?? 0.0,
      discountReason: json['discount_reason']?.toString() ?? '',
      opdService: json['opd_service']?.toString() ?? '',
      status: json['discount_approval_status'] == 'approved' 
          ? VoucherStatus.approved 
          : json['discount_approval_status'] == 'rejected'
              ? VoucherStatus.rejected
              : VoucherStatus.pending,
    );
  }
}

enum VoucherStatus { pending, approved, rejected }

class DiscountType {
  final int srlNo;
  final String discountName;
  final int isActive;

  DiscountType({
    required this.srlNo,
    required this.discountName,
    required this.isActive,
  });

  factory DiscountType.fromJson(Map<String, dynamic> json) {
    return DiscountType(
      srlNo: json['srl_no'] ?? 0,
      discountName: json['discount_name'] ?? '',
      isActive: json['is_active'] ?? 0,
    );
  }
}

class DiscountAuthorityModel {
  final int srlNo;
  final String employeeName;
  final String departmentName;
  final double discountLimit;
  final double usedLimit;
  final int isActive;

  DiscountAuthorityModel({
    required this.srlNo,
    required this.employeeName,
    required this.departmentName,
    required this.discountLimit,
    required this.usedLimit,
    required this.isActive,
  });

  factory DiscountAuthorityModel.fromJson(Map<String, dynamic> json) {
    return DiscountAuthorityModel(
      srlNo: json['srl_no'] ?? 0,
      employeeName: json['employee_name'] ?? json['authority_name'] ?? '',
      departmentName: json['department_name'] ?? json['designation'] ?? '',
      discountLimit: double.tryParse(json['discount_limit']?.toString() ?? '0') ?? 0.0,
      usedLimit: double.tryParse(json['used_limit']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] ?? 0,
    );
  }
}