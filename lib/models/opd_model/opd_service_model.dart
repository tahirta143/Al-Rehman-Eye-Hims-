class OpdServiceApiModel {
  final int srlNo;
  final String serviceId;
  final String serviceName;
  final String serviceHead;
  final String? imageUrl;
  final String serviceRate;
  final int requiredConsultant;
  final int sharedService;
  final int priceEditable;
  final int allowEmergencyService;
  final int allowOpdService;
  final String receiptType;
  final int isActive;
  final String createdAt;
  final String updatedAt;

  OpdServiceApiModel({
    required this.srlNo,
    required this.serviceId,
    required this.serviceName,
    required this.serviceHead,
    required this.imageUrl,
    required this.serviceRate,
    required this.requiredConsultant,
    required this.sharedService,
    required this.priceEditable,
    required this.allowEmergencyService,
    required this.allowOpdService,
    required this.receiptType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpdServiceApiModel.fromJson(Map<String, dynamic> json) {
    return OpdServiceApiModel(
      srlNo: json['srl_no'] is int
          ? json['srl_no'] as int
          : int.tryParse('${json['srl_no'] ?? 0}') ?? 0,
      serviceId: json['service_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      serviceHead: json['service_head'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      serviceRate: json['service_rate']?.toString() ?? '0',
      requiredConsultant: json['required_consultant'] is int
          ? json['required_consultant'] as int
          : int.tryParse('${json['required_consultant'] ?? 0}') ?? 0,
      sharedService: json['shared_service'] is int
          ? json['shared_service'] as int
          : int.tryParse('${json['shared_service'] ?? 0}') ?? 0,
      priceEditable: json['price_editable'] is int
          ? json['price_editable'] as int
          : int.tryParse('${json['price_editable'] ?? 0}') ?? 0,
      allowEmergencyService: json['allow_emergency_service'] is int
          ? json['allow_emergency_service'] as int
          : int.tryParse('${json['allow_emergency_service'] ?? 0}') ?? 0,
      allowOpdService: json['allow_opd_service'] is int
          ? json['allow_opd_service'] as int
          : int.tryParse('${json['allow_opd_service'] ?? 0}') ?? 0,
      receiptType: json['receipt_type'] as String? ?? '',
      isActive: json['is_active'] is int
          ? json['is_active'] as int
          : int.tryParse('${json['is_active'] ?? 0}') ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

