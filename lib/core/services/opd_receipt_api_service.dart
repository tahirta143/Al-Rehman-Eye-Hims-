import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../global/global_api.dart';
import 'auth_storage_service.dart';
import '../../models/opd_model/opd_service_model.dart';
import '../../models/opd_model/opd_receipt_model.dart';
import '../../models/voucher_model/voucher_model.dart';

class OpdReceiptApiService {
  final AuthStorageService _storage = AuthStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── GET /api/opd-patient-data (with pagination) ────────────────────────────
  Future<OpdReceiptsResult> fetchOpdReceipts({
    int page = 1,
    int limit = 50,
    String? mrNumber,
    bool? emergencyPaid,
  }) async {
    try {
      final headers = await _authHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (mrNumber != null) 'mr_number': mrNumber,
        if (emergencyPaid != null) 'emergency_paid': emergencyPaid.toString(),
      };

      final uri = Uri.parse('${GlobalApi.baseUrl}/opd-patient-data')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        return OpdReceiptsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = data['data'] as List<dynamic>;
          final receipts = list
              .map((e) => OpdReceiptApiModel.fromJson(e as Map<String, dynamic>))
              .toList();

          // Support both paginated and non-paginated API responses
          final totalCount = data['count'] as int? ??
              data['total'] as int? ??
              data['totalCount'] as int? ??
              receipts.length;
          final currentPage = data['currentPage'] as int? ??
              data['page'] as int? ??
              page;
          final totalPages = data['totalPages'] as int? ??
              data['pages'] as int? ??
              ((totalCount / limit).ceil());

          return OpdReceiptsResult(
            success: true,
            receipts: receipts,
            totalCount: totalCount,
            currentPage: currentPage,
            totalPages: totalPages,
          );
        }
        return OpdReceiptsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch OPD receipts',
        );
      }

      return OpdReceiptsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return OpdReceiptsResult(
        success: false,
        message: 'Failed to fetch OPD receipts: $e',
      );
    }
  }

  // ─── PUT /opd-patient-data/:id/refund ───────────────────────────────────────
  Future<RefundReceiptResult> refundOpdReceipt(
      int receiptSrlNo,
      double refundAmount,
      String refundReason,
      ) async {
    try {
      final headers = await _authHeaders();
      final payload = {
        'refund_amount': refundAmount,
        'refund_reason': refundReason,
      };

      debugPrint('📤 Calling refund API: ${GlobalApi.baseUrl}/opd-patient-data/$receiptSrlNo/refund');
      debugPrint('📤 Payload: $payload');

      final response = await http
          .put(
        Uri.parse('${GlobalApi.baseUrl}/opd-patient-data/$receiptSrlNo/refund'),
        headers: headers,
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 401) {
        return RefundReceiptResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final recJson = data['data'] as Map<String, dynamic>?;
          OpdReceiptApiModel? rec;
          if (recJson != null) {
            rec = OpdReceiptApiModel.fromJson(recJson);
          }
          return RefundReceiptResult(
            success: true,
            message: data['message'] as String? ?? 'Refund processed successfully',
            receipt: rec,
          );
        }
      }

      return RefundReceiptResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to process refund',
      );
    } catch (e) {
      debugPrint('❌ Refund error: $e');
      return RefundReceiptResult(
        success: false,
        message: 'Failed to process refund: $e',
      );
    }
  }

  // ─── GET /api/opd-services ───────────────────────────────────────────────────
  Future<OpdServicesResult> fetchOpdServices() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${GlobalApi.baseUrl}/opd-services'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return OpdServicesResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = data['data'] as List<dynamic>;
          final services = list
              .map((e) => OpdServiceApiModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return OpdServicesResult(success: true, services: services);
        }
        return OpdServicesResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch OPD services',
        );
      }

      return OpdServicesResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return OpdServicesResult(
        success: false,
        message: 'Failed to fetch OPD services: $e',
      );
    }
  }

  // ─── GET /api/lab/tests ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchLabTests() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${GlobalApi.baseUrl}/lab/tests'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch lab tests: $e'};
    }
  }

  // ─── GET /api/radiology-tests ──────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchRadiologyTests() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse('${GlobalApi.baseUrl}/radiology-tests'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch radiology tests: $e'};
    }
  }

  // ─── POST /api/opd-patient-data ──────────────────────────────────────────────
  Future<CreateOpdReceiptResult> createOpdReceipt(
      Map<String, dynamic> payload,
      ) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(
        Uri.parse('${GlobalApi.baseUrl}/opd-patient-data'),
        headers: headers,
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return CreateOpdReceiptResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['success'] == true) {
          final recJson = data['data'] as Map<String, dynamic>?;
          OpdReceiptApiModel? rec;
          if (recJson != null) {
            rec = OpdReceiptApiModel.fromJson(recJson);
          }
          return CreateOpdReceiptResult(
            success: true,
            message: data['message'] as String? ?? 'OPD receipt created successfully',
            receipt: rec,
            tokens: data['tokens'] as Map<String, dynamic>?,
          );
        }
      }

      return CreateOpdReceiptResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to create OPD receipt',
      );
    } catch (e) {
      return CreateOpdReceiptResult(
        success: false,
        message: 'Failed to create OPD receipt: $e',
      );
    }
  }

  // ─── PUT /opd-patient-data/:id/cancel ───────────────────────────────────────
  Future<CancelReceiptResult> cancelOpdReceipt(
      int receiptSrlNo,
      String cancelReason,
      ) async {
    try {
      final headers = await _authHeaders();
      final payload = {
        'cancel_details': cancelReason,
      };

      debugPrint('📤 Calling cancel API: ${GlobalApi.baseUrl}/opd-patient-data/$receiptSrlNo/cancel');
      debugPrint('📤 Payload: $payload');

      final response = await http
          .put(
        Uri.parse('${GlobalApi.baseUrl}/opd-patient-data/$receiptSrlNo/cancel'),
        headers: headers,
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return CancelReceiptResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return CancelReceiptResult(
            success: true,
            message: data['message'] as String? ?? 'Receipt cancelled successfully',
          );
        }
      }

      return CancelReceiptResult(
        success: false,
        message: data['message'] as String? ?? 'Failed to cancel receipt',
      );
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
      return CancelReceiptResult(
        success: false,
        message: 'Failed to cancel receipt: $e',
      );
    }
  }

  // ─── GET /opd-patient-data/pending-discounts ────────────────────────────────
  Future<PendingDiscountReceiptsResult> fetchPendingDiscountReceipts() async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(
        Uri.parse('${GlobalApi.baseUrl}/opd-patient-data/pending-discounts'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return PendingDiscountReceiptsResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final list = data['data'] ?? [];
          final receipts =
          (list as List).map((e) => VoucherDetail.fromJson(e)).toList();
          return PendingDiscountReceiptsResult(
            success: true,
            receipts: receipts,
          );
        }
        return PendingDiscountReceiptsResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to fetch pending discounts',
        );
      }

      return PendingDiscountReceiptsResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return PendingDiscountReceiptsResult(
        success: false,
        message: 'Failed to fetch pending discounts: $e',
      );
    }
  }

  // ─── PUT /opd-patient-data/:id/approve-discount ─────────────────────────────
  Future<ApproveDiscountResult> approveDiscount(
      int receiptSrlNo,
      int authoritySrlNo,
      ) async {
    try {
      final headers = await _authHeaders();
      final payload = {'authority_id': authoritySrlNo};

      final response = await http
          .put(
        Uri.parse(
          '${GlobalApi.baseUrl}/opd-patient-data/$receiptSrlNo/approve-discount',
        ),
        headers: headers,
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return ApproveDiscountResult(
          success: false,
          message: 'Session expired. Please log in again.',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ApproveDiscountResult(
            success: true,
            message: data['message'] as String? ?? 'Discount approved successfully',
          );
        }
        return ApproveDiscountResult(
          success: false,
          message: data['message'] as String? ?? 'Failed to approve discount',
        );
      }

      return ApproveDiscountResult(
        success: false,
        message: 'Server error: ${response.statusCode}',
      );
    } catch (e) {
      return ApproveDiscountResult(
        success: false,
        message: 'Failed to approve discount: $e',
      );
    }
  }

  // ─── PUT /opd-patient-data/:id/finalize-discount ────────────────────────────
  Future<Map<String, dynamic>> finalizeDiscountReceipt(int srlNo) async {
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(
        Uri.parse('${GlobalApi.baseUrl}/opd-patient-data/$srlNo/finalize-discount'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to finalize discount: $e',
      };
    }
  }
}

// ─── Result Classes ───────────────────────────────────────────────────────────

class OpdServicesResult {
  final bool success;
  final List<OpdServiceApiModel> services;
  final String? message;

  OpdServicesResult({
    required this.success,
    this.services = const [],
    this.message,
  });
}

class OpdReceiptsResult {
  final bool success;
  final List<OpdReceiptApiModel> receipts;
  final String? message;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  OpdReceiptsResult({
    required this.success,
    this.receipts = const [],
    this.message,
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });
}

class CancelReceiptResult {
  final bool success;
  final String? message;

  CancelReceiptResult({required this.success, this.message});
}

class RefundReceiptResult {
  final bool success;
  final String? message;
  final OpdReceiptApiModel? receipt;

  RefundReceiptResult({
    required this.success,
    this.message,
    this.receipt,
  });
}

class CreateOpdReceiptResult {
  final bool success;
  final String? message;
  final OpdReceiptApiModel? receipt;
  final Map<String, dynamic>? tokens;

  CreateOpdReceiptResult({
    required this.success,
    this.message,
    this.receipt,
    this.tokens,
  });
}

class PendingDiscountReceiptsResult {
  final bool success;
  final List<VoucherDetail> receipts;
  final String? message;

  PendingDiscountReceiptsResult({
    required this.success,
    this.receipts = const [],
    this.message,
  });
}

class ApproveDiscountResult {
  final bool success;
  final String? message;

  ApproveDiscountResult({required this.success, this.message});
}