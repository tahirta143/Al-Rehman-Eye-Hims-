import 'package:flutter/material.dart';

// ─── GP Prescription Models ──────────────────────────────────────────────────

class PrescriptionMedicine {
  final int? sr;
  final String medicineName;
  final int? medicineId;
  final bool isFormula;
  final String dosage;
  final double morning;
  final double afternoon;
  final double evening;
  final double night;
  final String forDays;
  final String qty;

  PrescriptionMedicine({
    this.sr,
    required this.medicineName,
    this.medicineId,
    this.isFormula = false,
    this.dosage = '',
    this.morning = 0,
    this.afternoon = 0,
    this.evening = 0,
    this.night = 0,
    this.forDays = '',
    this.qty = '',
  });

  Map<String, dynamic> toJson() => {
    'sr': sr,
    'medicine_name': medicineName,
    'medicine_id': medicineId,
    'is_formula': isFormula,
    'dosage': dosage,
    'morning': morning,
    'afternoon': afternoon,
    'evening': evening,
    'night': night,
    'for_days': forDays,
    'qty': qty,
  };

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) => PrescriptionMedicine(
    sr: json['sr'],
    medicineName: json['medicine_name'] ?? '',
    medicineId: json['medicine_id'],
    isFormula: json['is_formula'] ?? false,
    dosage: json['dosage'] ?? '',
    morning: (json['morning'] ?? 0).toDouble(),
    afternoon: (json['afternoon'] ?? 0).toDouble(),
    evening: (json['evening'] ?? 0).toDouble(),
    night: (json['night'] ?? 0).toDouble(),
    forDays: json['for_days']?.toString() ?? '',
    qty: json['qty']?.toString() ?? '',
  );
}

class PrescriptionInvestigation {
  final String investigationType;
  final String testName;

  PrescriptionInvestigation({
    required this.investigationType,
    required this.testName,
  });

  Map<String, dynamic> toJson() => {
    'investigation_type': investigationType,
    'test_name': testName,
  };

  factory PrescriptionInvestigation.fromJson(Map<String, dynamic> json) => PrescriptionInvestigation(
    investigationType: json['investigation_type'] ?? '',
    testName: json['test_name'] ?? '',
  );
}

class PrescriptionDiagnosis {
  final int questionId;
  final String questionText;
  final String? answerText;
  final dynamic answerValue;

  PrescriptionDiagnosis({
    required this.questionId,
    required this.questionText,
    this.answerText,
    this.answerValue,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'question_text': questionText,
    'answer_text': answerText,
    'answer_value': answerValue,
  };
}

// ─── Eye Prescription Models ─────────────────────────────────────────────────

class RefractionMatrix {
  String sph;
  String cyl;
  String axis;
  String va;
  String addition;

  RefractionMatrix({
    this.sph = '',
    this.cyl = '',
    this.axis = '',
    this.va = '',
    this.addition = '',
  });

  Map<String, dynamic> toJson() => {
    'sph': sph,
    'cyl': cyl,
    'axis': axis,
    'va': va,
    'addition': addition,
  };

  factory RefractionMatrix.fromJson(Map<String, dynamic> json) => RefractionMatrix(
    sph: json['sph'] ?? '',
    cyl: json['cyl'] ?? '',
    axis: json['axis'] ?? '',
    va: json['va'] ?? '',
    addition: json['addition'] ?? '',
  );
}

class VisionStats {
  String varValue;
  String ph;
  String ref;

  VisionStats({
    this.varValue = '',
    this.ph = '',
    this.ref = '',
  });

  Map<String, dynamic> toJson() => {
    'var': varValue,
    'ph': ph,
    'ref': ref,
  };

  factory VisionStats.fromJson(Map<String, dynamic> json) => VisionStats(
    varValue: json['var'] ?? '',
    ph: json['ph'] ?? '',
    ref: json['ref'] ?? '',
  );
}

class EyeSideItem {
  final String name;
  final String side; // L, R, B

  EyeSideItem({required this.name, required this.side});

  Map<String, dynamic> toJson() => {'name': name, 'side': side};

  factory EyeSideItem.fromJson(Map<String, dynamic> json) => EyeSideItem(
    name: json['name'] ?? '',
    side: json['side'] ?? 'B',
  );
}

class EyePrescriptionDetails {
  Map<String, bool> history;
  String otherHistory;
  
  // Refraction
  RefractionMatrix rightRefraction;
  RefractionMatrix leftRefraction;
  RefractionMatrix addRefraction;

  // Vision
  VisionStats rightVision;
  VisionStats leftVision;

  // Examination
  String presentingComplaints;
  List<EyeSideItem> complaints;
  List<EyeSideItem> examinations;

  // Management
  List<EyeSideItem> advised;
  String treatmentType;
  String remarks;
  String? operationDate;

  EyePrescriptionDetails({
    required this.history,
    this.otherHistory = '',
    required this.rightRefraction,
    required this.leftRefraction,
    required this.addRefraction,
    required this.rightVision,
    required this.leftVision,
    this.presentingComplaints = '',
    required this.complaints,
    required this.examinations,
    required this.advised,
    this.treatmentType = '',
    this.remarks = '',
    this.operationDate,
  });

  Map<String, dynamic> toJson() => {
    'optometrist': {
      'history': history,
      'otherHistory': otherHistory,
      'refraction': {
        'right': rightRefraction.toJson(),
        'left': leftRefraction.toJson(),
        'add': addRefraction.toJson(),
      },
      'vision': {
        'right': rightVision.toJson(),
        'left': leftVision.toJson(),
      },
    },
    'examination': {
      'presentingComplaints': presentingComplaints,
      'complaints': complaints.map((e) => e.toJson()).toList(),
      'examinations': examinations.map((e) => e.toJson()).toList(),
    },
    'management': {
      'advised': advised.map((e) => e.toJson()).toList(),
      'treatmentType': treatmentType,
      'remarks': remarks,
      'operationDate': operationDate,
    },
  };
}

// ─── Main Prescription Model ─────────────────────────────────────────────────

class PrescriptionModel {
  final int? id;
  final String mrNumber;
  final String doctorName;
  final int? doctorSrlNo;
  final String? receiptId;
  
  // Vitals
  final Map<String, String> vitals;

  // Notes
  final String historyExamination;
  final String treatment;
  final String consultantNotes;
  final String remarks;
  final String? referTo;

  // Lists
  final List<PrescriptionMedicine> medicines;
  final List<PrescriptionInvestigation> investigations;
  final List<String> instructions;
  final List<PrescriptionDiagnosis> diagnosis;

  // Eye specifics
  final EyePrescriptionDetails? eyeDetails;

  PrescriptionModel({
    this.id,
    required this.mrNumber,
    required this.doctorName,
    this.doctorSrlNo,
    this.receiptId,
    required this.vitals,
    this.historyExamination = '',
    this.treatment = '',
    this.consultantNotes = '',
    this.remarks = '',
    this.referTo,
    required this.medicines,
    required this.investigations,
    required this.instructions,
    required this.diagnosis,
    this.eyeDetails,
  });

  Map<String, dynamic> toJson() => {
    'mr_number': mrNumber,
    'doctor_name': doctorName,
    'doctor_srl_no': doctorSrlNo,
    'receipt_id': receiptId,
    'vitals': vitals,
    'history_examination': historyExamination,
    'treatment': treatment,
    'consultant_notes': consultantNotes,
    'remarks': remarks,
    'refer_to': referTo,
    'medicines': medicines.map((e) => e.toJson()).toList(),
    'investigations': investigations.map((e) => e.toJson()).toList(),
    'instructions': instructions,
    'diagnosis': diagnosis.map((e) => e.toJson()).toList(),
    'eye_details': eyeDetails?.toJson(),
  };
}
