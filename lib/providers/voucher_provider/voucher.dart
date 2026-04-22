// voucher_provider.dart
// State management provider for Discount Voucher Approval

import 'package:flutter/material.dart';
import '../../models/voucher_model/voucher_model.dart';
import '../../core/services/discount_api_service.dart';
import '../../core/services/opd_receipt_api_service.dart';

class VoucherProvider extends ChangeNotifier {
  final DiscountApiService _apiService = DiscountApiService();
  final OpdReceiptApiService _opdReceiptApiService = OpdReceiptApiService();

  // ─── State ──────────────────────────────────────────────────────────────────
  List<VoucherDetail> _pendingVouchers = [];
  List<VoucherDetail> _approvedVouchers = [];
  List<DiscountAuthorityModel> _authorities = [];

  VoucherDetail? _selectedVoucher;
  DiscountAuthorityModel? _selectedAuthority;
  bool _isLoading = false;
  bool _isApproving = false;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<VoucherDetail> get pendingVouchers => List.unmodifiable(_pendingVouchers);
  List<VoucherDetail> get approvedVouchers => List.unmodifiable(_approvedVouchers);
  List<DiscountAuthorityModel> get authorities => List.unmodifiable(_authorities);

  VoucherDetail? get selectedVoucher => _selectedVoucher;
  DiscountAuthorityModel? get selectedAuthority => _selectedAuthority;
  bool get isLoading => _isLoading;
  bool get isApproving => _isApproving;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _pendingVouchers.where((v) => v.status == VoucherStatus.pending).length;
  bool get hasPending => _pendingVouchers.any((v) => v.status == VoucherStatus.pending);

  List<VoucherDetail> get trulyPendingVouchers => 
    _pendingVouchers.where((v) => v.status == VoucherStatus.pending).toList();

  // ─── Init ────────────────────────────────────────────────────────────────────
  VoucherProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _setLoading(true);
    
    // Fetch authorities
    final auths = await _apiService.fetchAuthorities();
    _authorities = auths;

    // Fetch pending receipts
    final pendingRes = await _opdReceiptApiService.fetchPendingDiscountReceipts();
    if (pendingRes.success) {
      // Include both pending and approved (matches React logic)
      _pendingVouchers = pendingRes.receipts
          .where((r) => r.status == VoucherStatus.pending || r.status == VoucherStatus.approved)
          .toList();
    } else {
      _pendingVouchers = [];
      _errorMessage = pendingRes.message;
    }

    if (_pendingVouchers.isNotEmpty && (_selectedVoucher == null || !_pendingVouchers.any((v) => v.srlNo == _selectedVoucher!.srlNo))) {
      // Prefer selecting a pending one first
      final firstPending = _pendingVouchers.firstWhere(
        (v) => v.status == VoucherStatus.pending,
        orElse: () => _pendingVouchers.first,
      );
      _selectedVoucher = firstPending;
    }

    _setLoading(false);
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  /// Select a voucher from the pending list
  void selectVoucher(VoucherDetail voucher) {
    _selectedVoucher = voucher;
    _selectedAuthority = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Select a discount authority
  void selectAuthority(DiscountAuthorityModel? authority) {
    _selectedAuthority = authority;
    notifyListeners();
  }

  /// Validate and approve the current voucher discount
  Future<bool> approveDiscount() async {
    if (_selectedVoucher == null) {
      _errorMessage = 'No voucher selected.';
      notifyListeners();
      return false;
    }
    if (_selectedAuthority == null) {
      _errorMessage = 'Please select a discount authority.';
      notifyListeners();
      return false;
    }

    final discountAmt = _selectedVoucher!.discountAmount;
    final availableLimit = _selectedAuthority!.discountLimit - _selectedAuthority!.usedLimit;

    if (discountAmt > availableLimit) {
      _errorMessage = 'Insufficient limit. Available: ${availableLimit.toInt()}, Required: ${discountAmt.toInt()}';
      notifyListeners();
      return false;
    }

    _setApproving(true);

    final res = await _opdReceiptApiService.approveDiscount(_selectedVoucher!.srlNo, _selectedAuthority!.srlNo);
    
    if (res.success) {
      final approvedVoucher = _selectedVoucher!.copyWith(status: VoucherStatus.approved);
      _approvedVouchers.add(approvedVoucher);
      _pendingVouchers.removeWhere((v) => v.srlNo == _selectedVoucher!.srlNo);

      // Select next pending voucher if available
      _selectedVoucher = _pendingVouchers.isNotEmpty ? _pendingVouchers.first : null;
      _selectedAuthority = null;
      _errorMessage = null;

      // Refresh authorities limits
      _authorities = await _apiService.fetchAuthorities();
      
      _setApproving(false);
      return true;
    } else {
      _errorMessage = res.message ?? 'Unknown error occurred';
      _setApproving(false);
      return false;
    }
  }

  /// Reject the current voucher
  bool rejectDiscount() {
    if (_selectedVoucher == null) {
      _errorMessage = 'No voucher selected.';
      notifyListeners();
      return false;
    }

    final rejected = _selectedVoucher!.copyWith(status: VoucherStatus.rejected);
    _pendingVouchers.removeWhere((v) => v.srlNo == _selectedVoucher!.srlNo);

    _selectedVoucher = _pendingVouchers.isNotEmpty ? _pendingVouchers.first : null;
    _selectedAuthority = null;
    _errorMessage = null;

    notifyListeners();
    return true;
  }

  /// Finalize a voucher after approval (calling the backend)
  Future<Map<String, dynamic>> finalizeVoucher(int srlNo) async {
    _setApproving(true);
    try {
      final res = await _opdReceiptApiService.finalizeDiscountReceipt(srlNo);
      if (res['success'] == true) {
        _pendingVouchers.removeWhere((v) => v.srlNo == srlNo);
        if (_selectedVoucher?.srlNo == srlNo) {
          _selectedVoucher = _pendingVouchers.isNotEmpty ? _pendingVouchers.first : null;
        }
      }
      return res;
    } finally {
      _setApproving(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setApproving(bool val) {
    _isApproving = val;
    notifyListeners();
  }
}
