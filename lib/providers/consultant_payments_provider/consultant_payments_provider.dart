import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/consultant_payments_api_service.dart';
import '../../models/consultant_payment_model/consultant_payment_model.dart';

class ConsultantPaymentsProvider extends ChangeNotifier {
  final ConsultantPaymentsApiService _apiService = ConsultantPaymentsApiService();

  // ── Disposal guard (prevents notifyListeners crash after dispose) ──
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ── State ──
  ConsultantPaymentAnalytics? _analytics;
  List<DoctorBreakdownModel> _breakdown = [];
  List<PayoutRecordModel> _records = [];

  bool _loadingAnalytics = false;
  bool _loadingBreakdown = false;
  bool _loadingRecords = false;

  // ── submitting: tracks which doctor is being marked paid (by name) ──
  // null = nothing submitting, non-null = that doctor is being processed
  String? _submittingDoctorName;

  // ── Last payout result (for showing receipt/snackbar) ──
  String? _lastPayoutId;
  String? _lastPayoutDoctorName;
  String? _errorMessage;

  // ── Getters ──
  ConsultantPaymentAnalytics? get analytics => _analytics;
  List<DoctorBreakdownModel> get breakdown => List.unmodifiable(_breakdown);
  List<PayoutRecordModel> get records => List.unmodifiable(_records);
  bool get isLoading => _loadingAnalytics || _loadingBreakdown || _loadingRecords;
  bool get isSubmitting => _submittingDoctorName != null;
  String? get submittingDoctorName => _submittingDoctorName;
  String? get lastPayoutId => _lastPayoutId;
  String? get lastPayoutDoctorName => _lastPayoutDoctorName;
  String? get errorMessage => _errorMessage;

  /// Check if a specific doctor is currently being submitted
  bool isDoctorSubmitting(String doctorName) =>
      _submittingDoctorName == doctorName;

  // ── Load all dashboard data (analytics + breakdown + records) ──
  // Matches React's loadPayments: runs all 3 in parallel with Future.wait
  Future<void> loadDashboardData({
    required DateTime fromDate,
    required DateTime toDate,
    String? paid,
  }) async {
    if (_isDisposed) return;

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(toDate);

    _loadingAnalytics = true;
    _loadingBreakdown = true;
    _loadingRecords = true;
    _errorMessage = null;
    _safeNotify();

    try {
      // Run all 3 in parallel — matches React's Promise.allSettled
      final results = await Future.wait([
        _apiService.fetchAnalytics(fromDate: fromStr, toDate: toStr, paid: paid),
        _apiService.fetchDoctorBreakdown(fromDate: fromStr, toDate: toStr, paid: paid),
        _apiService.fetchPayouts(fromDate: fromStr, toDate: toStr),
      ]);

      if (_isDisposed) return;

      final analyticsRes = results[0] as ConsultantPaymentAnalyticsResult;
      final breakdownRes = results[1] as DoctorBreakdownResult;
      final recordsRes   = results[2] as PayoutRecordsResult;

      if (analyticsRes.success) _analytics = analyticsRes.analytics;
      if (breakdownRes.success) _breakdown = breakdownRes.breakdown;
      if (recordsRes.success)   _records   = recordsRes.records;
    } catch (e) {
      if (!_isDisposed) _errorMessage = 'Failed to load data: $e';
    }

    _loadingAnalytics = false;
    _loadingBreakdown = false;
    _loadingRecords   = false;
    _safeNotify();
  }

  // ── Refresh only payouts list ──
  Future<void> refreshPayouts({
    required DateTime fromDate,
    required DateTime toDate,
    String? doctorId,
  }) async {
    if (_isDisposed) return;

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr   = DateFormat('yyyy-MM-dd').format(toDate);

    _loadingRecords = true;
    _safeNotify();

    try {
      final res = await _apiService.fetchPayouts(
        fromDate: fromStr,
        toDate: toStr,
        doctorId: doctorId,
      );
      if (_isDisposed) return;
      if (res.success) _records = res.records;
    } catch (e) {
      debugPrint('❌ refreshPayouts error: $e');
    }

    _loadingRecords = false;
    _safeNotify();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MARK PAID — matches React's handleMarkPaid exactly:
  //   1. Sets submitting = true for that doctor
  //   2. POSTs to /consultant-payments/payouts
  //   3. On success, reloads dashboard data
  //   4. Stores payoutId for navigation/receipt display
  //   5. Sets submitting = false
  // ─────────────────────────────────────────────────────────────────────────────
  Future<MarkPaidResult> markDoctorPaid({
    required String doctorName,
    required DateTime fromDate,
    required DateTime toDate,
    String? createdBy, // username or full_name from auth
    String? paidFilter,
  }) async {
    if (_isDisposed) return MarkPaidResult(success: false, message: 'Provider disposed');
    if (_submittingDoctorName != null) {
      return MarkPaidResult(success: false, message: 'Another payout is in progress');
    }

    final fromStr = DateFormat('yyyy-MM-dd').format(fromDate);
    final toStr   = DateFormat('yyyy-MM-dd').format(toDate);

    _submittingDoctorName = doctorName;
    _errorMessage = null;
    _safeNotify();

    try {
      // Payload matches React's createDoctorPayout call exactly
      final payload = {
        'doctor_name': doctorName,
        'startDate': fromStr,
        'endDate': toStr,
        if (createdBy != null) 'created_by': createdBy,
      };

      final result = await _apiService.createDoctorPayout(payload);

      if (_isDisposed) return MarkPaidResult(success: false, message: 'Provider disposed');

      if (result.success) {
        _lastPayoutId = result.payoutId;
        _lastPayoutDoctorName = doctorName;

        // Reload dashboard to refresh breakdown + analytics (like React's loadPayments())
        await loadDashboardData(
          fromDate: fromDate,
          toDate: toDate,
          paid: paidFilter,
        );

        if (_isDisposed) return MarkPaidResult(success: true, payoutId: result.payoutId);

        _submittingDoctorName = null;
        _safeNotify();

        return MarkPaidResult(
          success: true,
          payoutId: result.payoutId,
          message: result.message,
        );
      } else {
        _errorMessage = result.message;
        _submittingDoctorName = null;
        _safeNotify();
        return MarkPaidResult(success: false, message: result.message);
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Failed to process payout: $e';
        _submittingDoctorName = null;
        _safeNotify();
      }
      return MarkPaidResult(success: false, message: 'Failed to process payout: $e');
    }
  }
}

// ─── Result class for markDoctorPaid ──────────────────────────────────────────
class MarkPaidResult {
  final bool success;
  final String? payoutId;
  final String? message;

  MarkPaidResult({required this.success, this.payoutId, this.message});
}