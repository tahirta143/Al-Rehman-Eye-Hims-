import 'dart:convert';

class NutritionPrescriptionModel {
  final String mrNumber;
  final String? receiptId;
  final int? doctorSrlNo;
  final String doctorName;
  
  // Vitals
  final String? temp;
  final String? bp;
  final String? pulse;
  final String? weight;
  final String? height;
  final String? bloodGroup;

  // Macros
  final String? totalKilocalories;
  final String? totalCarbs;
  final String? totalProteins;
  final String? totalFats;

  // Diet Specs
  final String? totalFluidIntake;
  final String? dietOrder;
  final String? dietType;
  final String? dietaryRecommendations;
  final String? lifestyleRecommendations;

  // Diet Plans
  final List<DietPlanModel> dietPlans;

  // Metadata / Joined Fields for Printing
  final String? patientFirstName;
  final String? patientLastName;
  final String? patientName;
  final String? patientAge;
  final String? patientGender;
  final String? patientPhone;
  final String? fatherHusbandName;
  final String? createdAt;

  NutritionPrescriptionModel({
    required this.mrNumber,
    this.receiptId,
    this.doctorSrlNo,
    required this.doctorName,
    this.temp,
    this.bp,
    this.pulse,
    this.weight,
    this.height,
    this.bloodGroup,
    this.totalKilocalories,
    this.totalCarbs,
    this.totalProteins,
    this.totalFats,
    this.totalFluidIntake,
    this.dietOrder,
    this.dietType,
    this.dietaryRecommendations,
    this.lifestyleRecommendations,
    required this.dietPlans,
    this.patientFirstName,
    this.patientLastName,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.patientPhone,
    this.fatherHusbandName,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'mr_number': mrNumber,
      'receipt_id': receiptId,
      'doctor_srl_no': doctorSrlNo,
      'doctor_name': doctorName,
      'temp': temp,
      'bp': bp,
      'pulse': pulse,
      'weight': weight,
      'height': height,
      'blood_group': bloodGroup,
      'total_kilocalories': totalKilocalories,
      'total_carbs': totalCarbs,
      'total_proteins': totalProteins,
      'total_fats': totalFats,
      'total_fluid_intake': totalFluidIntake,
      'diet_order': dietOrder,
      'diet_type': dietType,
      'dietary_recommendations': dietaryRecommendations,
      'lifestyle_recommendations': lifestyleRecommendations,
      'diet_plans': dietPlans.map((x) => x.toJson()).toList(),
      'patient_first_name': patientFirstName,
      'patient_last_name': patientLastName,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'patient_phone': patientPhone,
      'father_husband_name': fatherHusbandName,
      'created_at': createdAt,
    };
  }

  factory NutritionPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return NutritionPrescriptionModel(
      mrNumber: json['mr_number'] ?? '',
      receiptId: json['receipt_id'],
      doctorSrlNo: json['doctor_srl_no'],
      doctorName: json['doctor_name'] ?? '',
      temp: json['temp'],
      bp: json['bp'],
      pulse: json['pulse'],
      weight: json['weight'],
      height: json['height'],
      bloodGroup: json['blood_group'],
      totalKilocalories: json['total_kilocalories'],
      totalCarbs: json['total_carbs'],
      totalProteins: json['total_proteins'],
      totalFats: json['total_fats'],
      totalFluidIntake: json['total_fluid_intake'],
      dietOrder: json['diet_order'],
      dietType: json['diet_type'],
      dietaryRecommendations: json['dietary_recommendations'],
      lifestyleRecommendations: json['lifestyle_recommendations'],
      dietPlans: List<DietPlanModel>.from(
        (json['diet_plans'] as List? ?? []).map((x) => DietPlanModel.fromJson(x)),
      ),
      patientFirstName: json['patient_first_name'],
      patientLastName: json['patient_last_name'],
      patientName: json['patient_name'],
      patientAge: json['patient_age']?.toString(),
      patientGender: json['patient_gender'],
      patientPhone: json['patient_phone'],
      fatherHusbandName: json['father_husband_name'],
      createdAt: json['created_at'],
    );
  }
}

class DietPlanModel {
  final String mealPart;
  final String mealTime;
  final String foodItems;

  DietPlanModel({
    required this.mealPart,
    required this.mealTime,
    required this.foodItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'meal_part': mealPart,
      'meal_time': mealTime,
      'food_items': foodItems,
    };
  }

  factory DietPlanModel.fromJson(Map<String, dynamic> json) {
    return DietPlanModel(
      mealPart: json['meal_part'] ?? '',
      mealTime: json['meal_time'] ?? '',
      foodItems: json['food_items'] ?? '',
    );
  }
}
