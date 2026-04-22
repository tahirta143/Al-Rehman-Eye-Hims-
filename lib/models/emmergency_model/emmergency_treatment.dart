class EmergencyTreatment {
  final int id;
  final String name;

  EmergencyTreatment({
    required this.id,
    required this.name,
  });

  factory EmergencyTreatment.fromJson(Map<String, dynamic> json) {
    return EmergencyTreatment(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}