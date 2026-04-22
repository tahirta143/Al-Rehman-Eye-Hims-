// lib/models/opd_model/opd_ui_models.dart

import 'package:flutter/material.dart';
import 'opd_service_model.dart'; // your existing OpdServiceApiModel

// ════════════════════════════════════════════════════════════════════
//  OpdPatient
// ════════════════════════════════════════════════════════════════════
class OpdPatient {
  final String mrNo;
  final String fullName;
  final String phone;
  final String age;
  final String gender;
  final String address;
  final String city;
  final String panel;
  final String reference;

  const OpdPatient({
    required this.mrNo,
    required this.fullName,
    required this.phone,
    required this.age,
    required this.gender,
    required this.address,
    required this.city,
    required this.panel,
    required this.reference,
  });
}

// ════════════════════════════════════════════════════════════════════
//  OpdService  (UI model — built from OpdServiceApiModel)
// ════════════════════════════════════════════════════════════════════
class OpdService {
  final String   id;
  final String   name;
  final double   price;
  final String   category;         // normalised slug of service_head
  final IconData icon;
  final Color    color;
  final String?  imageUrl;
  final bool     allowEmergency;
  final bool     allowOpd;
  final bool     priceEditable;
  final bool     requiredConsultant;

  const OpdService({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.allowEmergency     = false,
    this.allowOpd           = true,
    this.priceEditable      = false,
    this.requiredConsultant = false,
  });

  /// Convert raw API model → UI model
  factory OpdService.fromApiModel(OpdServiceApiModel api) {
    final slug = normaliseSlug(api.serviceHead.trim().toLowerCase());
    final meta = categoryMeta(slug);
    return OpdService(
      id:                 api.serviceId,
      name:               api.serviceName,
      price:              double.tryParse(api.serviceRate) ?? 0.0,
      category:           slug,
      icon:               meta.icon,
      color:              meta.color,
      imageUrl:           (api.imageUrl?.isNotEmpty == true) ? api.imageUrl : null,
      allowEmergency:     api.allowEmergencyService == 1,
      allowOpd:           api.allowOpdService       == 1,
      priceEditable:      api.priceEditable         == 1,
      requiredConsultant: api.requiredConsultant     == 1,
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SelectedService
// ════════════════════════════════════════════════════════════════════
class SelectedService {
  final OpdService service;
  final int        qty;
  const SelectedService({required this.service, this.qty = 1});
}

// ════════════════════════════════════════════════════════════════════
//  Category metadata  (icon + colour + label per slug)
// ════════════════════════════════════════════════════════════════════
class CatMeta {
  final IconData icon;
  final Color    color;
  final String   label;
  const CatMeta(this.icon, this.color, this.label);
}

/// Normalise any service_head string → consistent slug
String normaliseSlug(String raw) {
  final s = raw.replaceAll(RegExp(r'[\s\-_]+'), '').toLowerCase();
  switch (s) {
    case 'xray':         return 'xray';
    case 'ctscan':       return 'ctscan';
    case 'mri':          return 'mri';
    case 'ultrasound':   return 'ultrasound';
    case 'laboratory':
    case 'lab':          return 'laboratory';
    case 'emergency':    return 'emergency';
    case 'consultation': return 'consultation';
    case 'opd':          return 'opd';
    default:             return s.isEmpty ? 'opd' : s;
  }
}

/// Return icon, colour and display label for a slug
CatMeta categoryMeta(String slug) {
  switch (slug) {
    case 'consultation':
      return const CatMeta(Icons.medical_information_rounded, Color(0xFF00B5AD), 'Consultation');
    case 'xray':
      return const CatMeta(Icons.radio_rounded,               Color(0xFF1E88E5), 'X-Ray');
    case 'ctscan':
      return const CatMeta(Icons.document_scanner_rounded,    Color(0xFF8E24AA), 'CT-Scan');
    case 'mri':
      return const CatMeta(Icons.blur_circular_rounded,       Color(0xFF00ACC1), 'MRI');
    case 'ultrasound':
      return const CatMeta(Icons.sensors_rounded,             Color(0xFF43A047), 'Ultrasound');
    case 'laboratory':
      return const CatMeta(Icons.biotech_rounded,             Color(0xFFF4511E), 'Laboratory');
    case 'emergency':
      return const CatMeta(Icons.emergency_rounded,           Color(0xFFE53935), 'Emergency');
    case 'opd':
    default:
      return const CatMeta(Icons.local_hospital_rounded,      Color(0xFFE53935), 'OPD');
  }
}

/// Build the chip-row map that the screen widget uses
Map<String, dynamic> buildCategoryChip(String slug) {
  final m = categoryMeta(slug);
  return {'id': slug, 'label': m.label, 'icon': m.icon, 'color': m.color};
}