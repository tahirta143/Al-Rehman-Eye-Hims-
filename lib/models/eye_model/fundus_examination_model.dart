import 'dart:convert';

class FundusExaminationModel {
  final String mrNumber;
  final String? receiptId;
  final List<FundusRecord> records;

  FundusExaminationModel({
    required this.mrNumber,
    this.receiptId,
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {
      'mr_number': mrNumber,
      'receipt_id': receiptId,
      'records': records.map((x) => x.toJson()).toList(),
    };
  }

  factory FundusExaminationModel.fromJson(Map<String, dynamic> json) {
    return FundusExaminationModel(
      mrNumber: json['mr_number'] ?? '',
      receiptId: json['receipt_id'],
      records: List<FundusRecord>.from(
        (json['records'] as List? ?? []).map((x) => FundusRecord.fromJson(x)),
      ),
    );
  }
}

class FundusRecord {
  final int? id;
  final String examinationDate;
  final Map<String, FundusFinding> findings;
  final String otherFindings;
  final String? doctorName;
  final int? doctorSrlNo;
  final String? receiptId;

  FundusRecord({
    this.id,
    required this.examinationDate,
    required this.findings,
    required this.otherFindings,
    this.doctorName,
    this.doctorSrlNo,
    this.receiptId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'examination_date': examinationDate,
      'findings': findings.map((k, v) => MapEntry(k, v.toJson())),
      'other_findings': otherFindings,
      'doctor_name': doctorName,
      'doctor_srl_no': doctorSrlNo,
      'receipt_id': receiptId,
    };
  }

  factory FundusRecord.fromJson(Map<String, dynamic> json) {
    Map<String, FundusFinding> findingsMap = {};
    if (json['findings'] != null) {
      (json['findings'] as Map<String, dynamic>).forEach((k, v) {
        findingsMap[k] = FundusFinding.fromJson(v);
      });
    }

    return FundusRecord(
      id: json['id'],
      examinationDate: json['examination_date'] ?? '',
      findings: findingsMap,
      otherFindings: json['other_findings'] ?? '',
      doctorName: json['doctor_name'],
      doctorSrlNo: json['doctor_srl_no'],
      receiptId: json['receipt_id'],
    );
  }
}

class FundusFinding {
  final bool? right;
  final bool? left;

  FundusFinding({this.right, this.left});

  Map<String, dynamic> toJson() => {
    'right': right,
    'left': left,
  };

  factory FundusFinding.fromJson(Map<String, dynamic> json) {
    return FundusFinding(
      right: json['right'],
      left: json['left'],
    );
  }

  FundusFinding copyWith({bool? right, bool? left, bool clearRight = false, bool clearLeft = false}) {
    return FundusFinding(
      right: clearRight ? null : (right ?? this.right),
      left: clearLeft ? null : (left ?? this.left),
    );
  }
}
