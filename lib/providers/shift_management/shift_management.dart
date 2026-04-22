import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/services/auth_storage_service.dart';
import '../../global/global_api.dart';
import '../../models/shift_model/shift_model.dart';

export '../../models/shift_model/shift_model.dart';

// ─── Receipt Model ────────────────────────────────────────────────────────────
class OpdReceipt {
  final int receiptId;
  final double totalAmount;
  final double discountAmount;
  final double paid;
  final double balance;
  final double drShareAmount;
  final bool isCancelled;

  OpdReceipt({
    required this.receiptId,
    required this.totalAmount,
    required this.discountAmount,
    required this.paid,
    required this.balance,
    required this.drShareAmount,
    required this.isCancelled,
  });

  factory OpdReceipt.fromJson(Map<String, dynamic> j) => OpdReceipt(
    receiptId: _int(j['receipt_id']),
    totalAmount: _d(j['total_amount']),
    discountAmount: _d(j['discount_amount']),
    paid: _d(j['paid']),
    balance: _d(j['balance']),
    drShareAmount: _d(j['dr_share_amount']),
    isCancelled: j['opd_cancelled'] == true || j['opd_cancelled'] == 1,
  );

  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;
  
  static int _int(dynamic v) =>
      int.tryParse(v?.toString() ?? '0') ?? 0;
}

// ─── Shift Summary ────────────────────────────────────────────────────────────
class ShiftSummary {
  final int receiptCount;
  final int receiptFrom;
  final int receiptTo;
  final double totalAmount;
  final double totalDiscount;
  final double totalPaid;
  final double totalBalance;
  final double drShareAmount;

  ShiftSummary({
    required this.receiptCount,
    required this.receiptFrom,
    required this.receiptTo,
    required this.totalAmount,
    required this.totalDiscount,
    required this.totalPaid,
    required this.totalBalance,
    required this.drShareAmount,
  });

  // Mirrors React's local calculation: filter cancelled, then sum
  static ShiftSummary fromReceipts(List<OpdReceipt> receipts) {
    final active = receipts.where((r) => !r.isCancelled).toList();
    return ShiftSummary(
      receiptCount: receipts.length,
      receiptFrom: receipts.isNotEmpty ? receipts.first.receiptId : 0,
      receiptTo: receipts.isNotEmpty ? receipts.last.receiptId : 0,
      totalAmount: active.fold(0, (s, r) => s + r.totalAmount),
      totalDiscount: active.fold(0, (s, r) => s + r.discountAmount),
      totalPaid: active.fold(0, (s, r) => s + r.paid),
      totalBalance: active.fold(0, (s, r) => s + r.balance),
      drShareAmount: active.fold(0, (s, r) => s + r.drShareAmount),
    );
  }

  static ShiftSummary empty() => ShiftSummary(
    receiptCount: 0,
    receiptFrom: 0,
    receiptTo: 0,
    totalAmount: 0,
    totalDiscount: 0,
    totalPaid: 0,
    totalBalance: 0,
    drShareAmount: 0,
  );
}

// ─── Timeline status enum ─────────────────────────────────────────────────────
enum ShiftDateStatus { notStarted, open, closed }

// ─── Provider ─────────────────────────────────────────────────────────────────
class ShiftProvider extends ChangeNotifier {
  static const String _baseUrl = '${GlobalApi.baseUrl}/shifts';
  // ⚠️ Verify this path matches your backend — check opdReceiptService.js
  static const String _receiptUrl = '${GlobalApi.baseUrl}/opd-patient-data';

  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── State ──────────────────────────────────────────────────────────────────
  ShiftModel _currentShift = ShiftModel.empty();
  List<ShiftModel> _allShifts = [];
  List<ShiftModel> _shiftsForDate = [];
  ShiftSummary _shiftSummary = ShiftSummary.empty();
  DateTime _selectedDate = DateTime.now();

  bool isLoading = false;
  bool isClosing = false;
  bool isSummaryLoading = false;
  String? errorMessage;

  // ── Getters ────────────────────────────────────────────────────────────────
  ShiftModel get shift => _currentShift;
  ShiftModel get currentShift => _currentShift;
  List<ShiftModel> get allShifts => _allShifts;
  List<ShiftModel> get activeShifts =>
      _allShifts.where((s) => !s.isClosed).toList();
  ShiftSummary get shiftSummary => _shiftSummary;
  DateTime get selectedDate => _selectedDate;
  bool get isClosed => _currentShift.isClosed;
  bool get hasActiveShift =>
      _currentShift.shiftId != 0 && !_currentShift.isClosed;

  // Legacy getters (kept for backward compatibility)
  double get grossAmount => _shiftSummary.totalAmount;
  double get totalCollected => _shiftSummary.totalPaid;
  int get receiptCount => _shiftSummary.receiptCount;
  String get receiptsRange =>
      _shiftSummary.receiptCount == 0
          ? '--'
          : '${_shiftSummary.receiptFrom}-${_shiftSummary.receiptTo}';

  ShiftProvider() {
    _init();
  }

  Future<void> _init() async {
    await fetchCurrentShift();
    await fetchAllShifts();
    await _fetchShiftsForDate(_selectedDate);
  }

  // ── Date Selection ─────────────────────────────────────────────────────────
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await _fetchShiftsForDate(date);
  }

  // ── Timeline status for a given shift type on the selected date ────────────
  ShiftDateStatus getShiftStatusForDate(String shiftType) {
    final s = _shiftsForDate
        .where((s) => s.shiftType == shiftType)
        .firstOrNull;
    if (s == null) return ShiftDateStatus.notStarted;
    if (s.isClosed) return ShiftDateStatus.closed;
    return ShiftDateStatus.open;
  }

  // ── GET current open shift ─────────────────────────────────────────────────
  Future<void> fetchCurrentShift() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authHeaders();
      developer.log('📡 GET $_baseUrl/current', name: 'ShiftProvider');
      final response =
      await http.get(Uri.parse('$_baseUrl/current'), headers: headers);
      developer.log('📥 ${response.statusCode}: ${response.body}',
          name: 'ShiftProvider');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          _currentShift = ShiftModel.fromJson(json['data']);
          // Load receipts to calculate amounts — mirrors React's loadShiftDetails
          await _loadShiftDetails(_currentShift.shiftId);
        } else {
          _currentShift = ShiftModel.empty();
          _shiftSummary = ShiftSummary.empty();
          errorMessage = json['message'] ?? 'No active shift found.';
        }
      } else if (response.statusCode == 404) {
        _currentShift = ShiftModel.empty();
        _shiftSummary = ShiftSummary.empty();
        errorMessage = 'No active shift found.';
      } else if (response.statusCode == 401) {
        errorMessage = 'Session expired. Please log in again.';
      } else {
        errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e, stack) {
      errorMessage = 'Network error. Check your connection.';
      developer.log('💥 fetchCurrentShift: $e',
          name: 'ShiftProvider', error: e, stackTrace: stack);
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Load receipts & compute summary (mirrors React loadShiftDetails) ────────
  Future<void> _loadShiftDetails(int shiftId) async {
    if (shiftId == 0) return;
    isSummaryLoading = true;
    notifyListeners();

    try {
      final headers = await _authHeaders();
      final url = '$_receiptUrl/shift/$shiftId';
      developer.log('📡 GET $url', name: 'ShiftProvider');
      final response =
      await http.get(Uri.parse(url), headers: headers);
      developer.log('📥 receipts ${response.statusCode}', name: 'ShiftProvider');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final receipts = (json['data'] as List)
              .map((e) => OpdReceipt.fromJson(e))
              .toList();
          _shiftSummary = ShiftSummary.fromReceipts(receipts);
          developer.log(
              '✅ ${receipts.length} receipts | '
                  'gross=${_shiftSummary.totalAmount} paid=${_shiftSummary.totalPaid}',
              name: 'ShiftProvider');
        }
      }
    } catch (e, stack) {
      developer.log('💥 _loadShiftDetails: $e',
          name: 'ShiftProvider', error: e, stackTrace: stack);
    }

    isSummaryLoading = false;
    notifyListeners();
  }

  // ── GET shifts by date (for timeline) ─────────────────────────────────────
  Future<void> _fetchShiftsForDate(DateTime date) async {
    try {
      final headers = await _authHeaders();
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await http.get(
          Uri.parse('$_baseUrl/date/$dateStr'),
          headers: headers);
      developer.log('📥 shiftsForDate ${response.statusCode}',
          name: 'ShiftProvider');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _shiftsForDate = (json['data'] as List)
              .map((e) => ShiftModel.fromJson(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e, stack) {
      developer.log('💥 _fetchShiftsForDate: $e',
          name: 'ShiftProvider', error: e, stackTrace: stack);
    }
  }

  // ── GET all shifts ─────────────────────────────────────────────────────────
  Future<void> fetchAllShifts() async {
    try {
      final headers = await _authHeaders();
      final response =
      await http.get(Uri.parse(_baseUrl), headers: headers);
      developer.log('📥 allShifts ${response.statusCode}', name: 'ShiftProvider');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          _allShifts = (json['data'] as List)
              .map((e) => ShiftModel.fromJson(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e, stack) {
      developer.log('💥 fetchAllShifts: $e',
          name: 'ShiftProvider', error: e, stackTrace: stack);
    }
  }

  // ── PUT close shift ────────────────────────────────────────────────────────
  Future<bool> closeShift(String closedBy, double cashInHand) async {
    if (_currentShift.shiftId == 0) return false;

    isClosing = true;
    notifyListeners();

    // Match React API: send both closed_by and cash_in_hand
    final body = jsonEncode({'closed_by': closedBy, 'cash_in_hand': cashInHand});

    try {
      final headers = await _authHeaders();
      final url = '$_baseUrl/${_currentShift.shiftId}/close';
      developer.log('📡 PUT $url', name: 'ShiftProvider');
      final response =
      await http.put(Uri.parse(url), headers: headers, body: body);
      developer.log('📥 closeShift ${response.statusCode}: ${response.body}',
          name: 'ShiftProvider');

      if (response.statusCode == 200) {
        await fetchCurrentShift();
        await fetchAllShifts();
        await _fetchShiftsForDate(_selectedDate);
        isClosing = false;
        notifyListeners();
        return true;
      }
    } catch (e, stack) {
      developer.log('💥 closeShift: $e',
          name: 'ShiftProvider', error: e, stackTrace: stack);
    }

    isClosing = false;
    notifyListeners();
    return false;
  }

  // ── Refresh all ────────────────────────────────────────────────────────────
  Future<void> refresh() async {
    await fetchCurrentShift();
    await fetchAllShifts();
    await _fetchShiftsForDate(_selectedDate);
  }
}