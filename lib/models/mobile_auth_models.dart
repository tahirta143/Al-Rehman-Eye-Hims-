class PatientRegisterRequest {
  final String phone;
  final String fullName;
  final String? gender;
  final String? city;
  final String? age;

  PatientRegisterRequest({
    required this.phone,
    required this.fullName,
    this.gender,
    this.city,
    this.age,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'full_name': fullName,
    'gender': gender,
    'city': city,
    'age': age,
  };
}

class OTPVerifyRequest {
  final String phone;
  final String otp;

  OTPVerifyRequest({required this.phone, required this.otp});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'otp': otp,
  };
}

class DoctorLoginRequest {
  final String phone;
  final String password;

  DoctorLoginRequest({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
  };
}

class PatientPortalLoginRequest {
  final String mrNumber;
  final String password;

  PatientPortalLoginRequest({required this.mrNumber, required this.password});

  Map<String, dynamic> toJson() => {
    'mr_number': mrNumber,
    'password': password,
  };
}

class MobileUser {
  final int id;
  final String phone;
  final String role;
  final String fullName;
  final String? mrNumber;
  final int? doctorSrlNo;

  MobileUser({
    required this.id,
    required this.phone,
    required this.role,
    required this.fullName,
    this.mrNumber,
    this.doctorSrlNo,
  });

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    return MobileUser(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
      phone: json['phone'] ?? (json['telephone'] ?? ''),
      role: json['role'] ?? 'patient',
      fullName: json['full_name'] ?? (json['patient_name'] ?? 'Guest'),
      mrNumber: json['mr_number'],
      doctorSrlNo: json['doctor_srl_no'],
    );
  }
}
