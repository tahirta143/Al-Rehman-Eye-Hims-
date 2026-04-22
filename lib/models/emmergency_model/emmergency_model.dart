class EmergencyQueuePatient {
  final String receiptId;
  final String mrNo;
  final String name;
  final String age;
  final String gender;
  final DateTime admittedSince;

  EmergencyQueuePatient({
    required this.receiptId,
    required this.mrNo,
    required this.name,
    required this.age,
    required this.gender,
    required this.admittedSince,
  });

  factory EmergencyQueuePatient.fromJson(Map<String, dynamic> json) {
    return EmergencyQueuePatient(
      receiptId: json['receipt_id'] ?? '',
      mrNo: json['patient_mr_number'] ?? '',
      name: json['patient_name'] ?? '',
      age: json['patient_age']?.toString() ?? '',
      gender: json['patient_gender'] ?? '',
      admittedSince:
      DateTime.tryParse(json['admitted_since'] ?? '') ?? DateTime.now(),
    );
  }
}