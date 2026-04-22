import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/fundus_api_service.dart';
import '../../models/eye_model/fundus_examination_model.dart';
import '../../providers/prescription_provider/prescription_provider.dart';

class FundusProvider extends ChangeNotifier {
  final FundusApiService _apiService = FundusApiService();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<FundusRecord> _records = [];
  Timer? _consultationTimer;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<FundusRecord> get records => _records;

  // ─── Actions ─────────────────────────────────────────────────────

  void startConsultationTimer(PrescriptionProvider prescriptionProvider) {
    _consultationTimer?.cancel();
    prescriptionProvider.loadConsultationPatients(); // Initial load
    _consultationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      prescriptionProvider.loadConsultationPatients();
    });
  }

  void stopConsultationTimer() {
    _consultationTimer?.cancel();
  }

  Future<void> fetchHistory(String mrNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.fetchFundusHistory(mrNumber);
      if (res['success'] == true) {
        final List<dynamic> data = res['data'] ?? [];
        _records = data.map((r) => FundusRecord(
          id: r['id'],
          examinationDate: (r['examination_date'] ?? r['created_at']).toString().split('T')[0],
          findings: _parseFindings(r['findings']),
          otherFindings: r['other_findings'] ?? '',
          doctorName: r['doctor_name'],
          doctorSrlNo: r['doctor_srl_no'],
          receiptId: r['receipt_id'],
        )).toList();
        
        // Sort by date descending
        _records.sort((a, b) => b.examinationDate.compareTo(a.examinationDate));
      } else {
        _errorMessage = res['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Map<String, FundusFinding> _parseFindings(dynamic findings) {
    final Map<String, FundusFinding> result = {};
    if (findings is Map) {
      findings.forEach((k, v) {
        result[k.toString()] = FundusFinding.fromJson(Map<String, dynamic>.from(v));
      });
    }
    return result;
  }

  void addDateColumn(String date, String? doctorName, int? doctorSrlNo, String? receiptId) {
    if (_records.any((r) => r.examinationDate == date)) return;

    final newRecord = FundusRecord(
      examinationDate: date,
      findings: _createEmptyFindings(),
      otherFindings: '',
      doctorName: doctorName,
      doctorSrlNo: doctorSrlNo,
      receiptId: receiptId,
    );

    _records.add(newRecord);
    _records.sort((a, b) => b.examinationDate.compareTo(a.examinationDate));
    notifyListeners();
  }

  void removeRecord(int index) {
    _records.removeAt(index);
    notifyListeners();
  }

  void toggleFinding(int recordIndex, String key, String eye, bool? value) {
    final record = _records[recordIndex];
    final currentFinding = record.findings[key] ?? FundusFinding();
    
    FundusFinding updatedFinding;
    if (eye == 'right') {
      updatedFinding = currentFinding.copyWith(right: value, clearRight: value == null);
    } else {
      updatedFinding = currentFinding.copyWith(left: value, clearLeft: value == null);
    }

    record.findings[key] = updatedFinding;
    notifyListeners();
  }

  void updateOtherFindings(int recordIndex, String value) {
    _records[recordIndex] = FundusRecord(
      id: _records[recordIndex].id,
      examinationDate: _records[recordIndex].examinationDate,
      findings: _records[recordIndex].findings,
      otherFindings: value,
      doctorName: _records[recordIndex].doctorName,
      doctorSrlNo: _records[recordIndex].doctorSrlNo,
      receiptId: _records[recordIndex].receiptId,
    );
    notifyListeners();
  }

  Future<bool> saveBatch(String mrNumber, String? receiptId) async {
    if (_records.isEmpty) return false;
    
    _isSaving = true;
    notifyListeners();

    final payload = {
      'mr_number': mrNumber,
      'receipt_id': receiptId,
      'records': _records.map((r) => r.toJson()).toList(),
    };

    final res = await _apiService.saveFundusExaminationsBulk(payload);
    
    if (res['success'] == true) {
      await fetchHistory(mrNumber); // Refresh to get IDs
    }

    _isSaving = false;
    notifyListeners();
    return res['success'] == true;
  }

  Map<String, FundusFinding> _createEmptyFindings() {
    final Map<String, FundusFinding> findings = {};
    final keys = [
      'dm_fundus', 'normal', 'bgdr', 'maculopathy', 'focal', 'diffuse', 'csme', 'ppdr', 'pdr',
      'htn_normal', 'htn_grade1', 'htn_grade2', 'htn_grade3', 'htn_grade4',
      'vid_hemorrhages', 'trrd', 'rubeosis'
    ];
    for (var key in keys) {
      findings[key] = FundusFinding();
    }
    return findings;
  }

  @override
  void dispose() {
    _consultationTimer?.cancel();
    super.dispose();
  }
}
