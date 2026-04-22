// discount_voucher_approval_screen.dart
// Uses BaseScaffold for consistent app shell (drawer + header)
// State managed by VoucherProvider (provider package)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';// adjust path if needed
import '../../custum widgets/drawer/base_scaffold.dart';
import '../../models/voucher_model/voucher_model.dart';
import '../../providers/voucher_provider/voucher.dart';
import '../../custum widgets/custom_loader.dart';
import '../../custum widgets/animations/animations.dart';
import 'package:animate_do/animate_do.dart';

// ─── Theme constants ──────────────────────────────────────────────────────────
const Color kPrimary      = Color(0xFF00B5AD);
const Color kPrimaryLight = Color(0xFFE0F7F6);
const Color kBackground   = Color(0xFFF0F4F8);
const Color kCard         = Colors.white;
const Color kText         = Color(0xFF2D3748);
const Color kSubText      = Color(0xFF718096);
const Color kBorder       = Color(0xFFE2E8F0);
const Color kPayable      = Color(0xFFFFB3C6);
const Color kWarning      = Color(0xFFE6A817);

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Labeled read-only info field
class VoucherInfoField extends StatelessWidget {
  final String label;
  final String value;
  const VoucherInfoField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: kSubText, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: Text(value.isEmpty ? '—' : value,
              style: const TextStyle(
                  fontSize: 13, color: kText, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

/// Section card with teal header strip and icon
class VoucherSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const VoucherSectionCard(
      {super.key, required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: const Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(children: [
              Icon(icon, color: kPrimary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

/// Single service row inside the services table
class ServiceTableRow extends StatelessWidget {
  final ServiceItem item;
  const ServiceTableRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5)))),
      child: Row(children: [
        SizedBox(width: 30, child: Text('${item.srNo}', style: const TextStyle(fontSize: 12, color: kSubText))),
        Expanded(child: Text(item.service, style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w500))),
        SizedBox(width: 60, child: Text(item.type, style: const TextStyle(fontSize: 12, color: kSubText))),
        SizedBox(width: 50, child: Text(item.rate.toInt().toString(), style: const TextStyle(fontSize: 12, color: kText), textAlign: TextAlign.right)),
        SizedBox(width: 30, child: Text('${item.qty}', style: const TextStyle(fontSize: 12, color: kText), textAlign: TextAlign.center)),
        SizedBox(width: 50, child: Text(item.total.toInt().toString(), style: const TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
      ]),
    );
  }
}

/// Pending approval tile used inside the dropdown panel
class PendingApprovalTile extends StatelessWidget {
  final VoucherDetail voucher;
  final bool isSelected;
  final VoidCallback onTap;
  const PendingApprovalTile(
      {super.key, required this.voucher, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: kPrimary.withOpacity(0.4)) : null,
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(voucher.invoiceId,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSelected ? kPrimary : kText)),
              const SizedBox(height: 2),
              Text(voucher.patientName,
                  style: TextStyle(fontSize: 12, color: isSelected ? kPrimary : kSubText)),
              Text('MR: ${voucher.patientMrNumber}',
                  style: const TextStyle(fontSize: 10, color: kSubText)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kWarning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Rs. ${voucher.payable.toInt()}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: kWarning)),
          ),
        ]),
      ),
    );
  }
}

/// Right-aligned amount summary row (Total / Discount / Payable)
class AmountSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPayable;
  final bool isBold;
  const AmountSummaryRow({
    super.key, required this.label, required this.value,
    this.isPayable = false, this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: kText)),
      const SizedBox(width: 12),
      Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPayable ? kPayable.withOpacity(0.3) : kBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPayable ? kPayable : kBorder),
        ),
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isPayable ? const Color(0xFFD63384) : kText)),
      ),
    ]);
  }
}

/// Styled labeled dropdown
class VoucherDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  const VoucherDropdown({
    super.key, required this.label, required this.value,
    required this.items, required this.onChanged, this.hint = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: kSubText, letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value, items: items, onChanged: onChanged, isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            hint: Text(hint, style: const TextStyle(fontSize: 13, color: kSubText)),
            style: const TextStyle(fontSize: 13, color: kText),
          ),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN  — uses BaseScaffold
// ═══════════════════════════════════════════════════════════════════════════════

class DiscountVoucherApprovalScreen extends StatefulWidget {
  const DiscountVoucherApprovalScreen({super.key});

  @override
  State<DiscountVoucherApprovalScreen> createState() =>
      _DiscountVoucherApprovalScreenState();
}

class _DiscountVoucherApprovalScreenState
    extends State<DiscountVoucherApprovalScreen> {
  bool _isPendingPanelOpen = false;

  // ── Pending badge widget injected into BaseScaffold actions ────────────────
  Widget _pendingBadge(VoucherProvider p) {
    return GestureDetector(
      onTap: () => setState(() => _isPendingPanelOpen = !_isPendingPanelOpen),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.pending_actions, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text('${p.pendingCount} Pending',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(
              _isPendingPanelOpen ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
              size: 16),
        ]),
      ),
    );
  }

  // ── Approve logic ──────────────────────────────────────────────────────────
  void _handleApprove(VoucherProvider p) async {
    final ok = await p.approveDiscount();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.errorMessage ?? 'Validation failed'),
          backgroundColor: Colors.orange));
      p.clearError();
      return;
    }
    setState(() => _isPendingPanelOpen = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Discount approved successfully!'),
        backgroundColor: kPrimary));
  }

  void _showApproveDialog(VoucherProvider p) {
    final v = p.selectedVoucher!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle_rounded, color: kPrimary),
          SizedBox(width: 8),
          Text('Approve Discount'),
        ]),
        content: Text(
          'Approve ${v.discountPercentage.toStringAsFixed(1)}% discount '
              '(Rs. ${v.discountAmount.toInt()}) for ${v.patientName}?\n\n'
              'Payable: Rs. ${v.payable.toInt()}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleApprove(p);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        // Show spinner until data loads
        if (provider.isLoading) {
          return BaseScaffold(
            title: 'Discount Voucher Approval',
            drawerIndex: 10, // no drawer item selected for this screen
            showNotificationIcon: false,
            body: const CustomPageTransition(
              child: Center(
                  child: CustomLoader(size: 50, color: kPrimary)),
            ),
          );
        }

        final v = provider.selectedVoucher;

        return BaseScaffold(
          title: 'Discount Voucher Approval',
          drawerIndex: 10,          // set correct index once added to drawer
          showNotificationIcon: false,
          // ── Pending badge injected as a custom action ──────────────────
          actions: [_pendingBadge(provider)],
          body: CustomPageTransition(
            child: Stack(
              children: [
                // Main scrollable content
                Positioned.fill(
                  child: v == null
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).size.width > 800 
                          ? MediaQuery.of(context).size.width * 0.15 
                          : MediaQuery.of(context).size.width > 600 
                              ? MediaQuery.of(context).size.width * 0.08 
                              : 12,
                      12,
                      MediaQuery.of(context).size.width > 800 
                          ? MediaQuery.of(context).size.width * 0.15 
                          : MediaQuery.of(context).size.width > 600 
                              ? MediaQuery.of(context).size.width * 0.08 
                              : 12,
                      120,
                    ),
                    child: Column(children: [
                      FadeInUp(delay: const Duration(milliseconds: 100), child: _buildVoucherDetailsCard(v)),
                      const SizedBox(height: 12),
                      FadeInUp(delay: const Duration(milliseconds: 200), child: _buildServicesCard(v)),
                      const SizedBox(height: 12),
                      FadeInUp(delay: const Duration(milliseconds: 300), child: _buildDiscountCard(v, provider)),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),

                // Pending approvals dropdown panel (overlay)
                if (_isPendingPanelOpen)
                  Positioned(
                    top: 8,
                    right: 12,
                    width: MediaQuery.of(context).size.width > 400 ? 320 : MediaQuery.of(context).size.width * 0.85,
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 300),
                      child: _buildPendingPanel(provider),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Pending Panel ───────────────────────────────────────────────────────────
  Widget _buildPendingPanel(VoucherProvider p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        mainAxisSize: MainAxisSize.min,
        children: [
        Row(children: [
          const Icon(Icons.hourglass_empty, color: kWarning, size: 16),
          const SizedBox(width: 6),
          const Text('Pending Approvals',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: kSubText),
            onPressed: p.loadData,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const Divider(height: 12),
        if (!p.hasPending)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No pending approvals',
                  style: TextStyle(color: kSubText)),
            ),
          )
        else
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: p.trulyPendingVouchers.map((voucher) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: PendingApprovalTile(
                    voucher: voucher,
                    isSelected:
                    voucher.invoiceId == p.selectedVoucher?.invoiceId,
                    onTap: () {
                      p.selectVoucher(voucher);
                      setState(() => _isPendingPanelOpen = false);
                    },
                  ),
                )).toList(),
              ),
            ),
          ),
      ]),
    );
  }

  // ── Voucher Details Card ────────────────────────────────────────────────────
  Widget _buildVoucherDetailsCard(VoucherDetail v) {
    return VoucherSectionCard(
      title: 'Voucher Details',
      icon: Icons.receipt_long_rounded,
      child: Column(children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: Text('Receipt ID  ${v.invoiceId}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: VoucherInfoField(label: 'INVOICE', value: v.invoiceId)),
          const SizedBox(width: 10),
          Expanded(child: VoucherInfoField(label: 'DATE', value: v.date)),
          const SizedBox(width: 10),
          Expanded(child: VoucherInfoField(label: 'TIME', value: v.time)),
        ]),
        const SizedBox(height: 10),
        VoucherInfoField(label: 'NAME', value: v.patientName),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: VoucherInfoField(label: 'AGE', value: '${v.age}')),
          const SizedBox(width: 10),
          Expanded(child: VoucherInfoField(label: 'GENDER', value: v.gender)),
          const SizedBox(width: 10),
          Expanded(child: VoucherInfoField(label: 'PHONE', value: v.phone)),
        ]),
        const SizedBox(height: 10),
        VoucherInfoField(label: 'ADDRESS', value: v.address),
      ]),
    );
  }

  // ── Services Card ───────────────────────────────────────────────────────────
  Widget _buildServicesCard(VoucherDetail v) {
    return VoucherSectionCard(
      title: 'Services',
      icon: Icons.local_hospital_rounded,
      child: Column(children: [
        Row(children: const [
          SizedBox(width: 30, child: Text('SR.#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText))),
          Expanded(child: Text('SERVICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText))),
          SizedBox(width: 60, child: Text('TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText))),
          SizedBox(width: 50, child: Text('RATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText), textAlign: TextAlign.right)),
          SizedBox(width: 30, child: Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText), textAlign: TextAlign.center)),
          SizedBox(width: 50, child: Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubText), textAlign: TextAlign.right)),
        ]),
        const Divider(height: 8),
        ...v.services.map((s) => ServiceTableRow(item: s)),
      ]),
    );
  }

  // ── Discount Card ───────────────────────────────────────────────────────────
  Widget _buildDiscountCard(VoucherDetail v, VoucherProvider p) {
    final auth = p.selectedAuthority;
    return VoucherSectionCard(
      title: 'Discount & Approval',
      icon: Icons.discount_rounded,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AmountSummaryRow(label: 'Total', value: v.total.toInt().toString()),
        const SizedBox(height: 12),
        VoucherDropdown<DiscountAuthorityModel>(
          label: 'DISCOUNT BY', hint: 'Select Authority', value: auth,
          items: p.authorities
              .map((a) => DropdownMenuItem(
              value: a,
              child: Text(a.employeeName, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: p.selectAuthority,
        ),
        const SizedBox(height: 10),
        if (auth != null) ...[
          VoucherInfoField(label: 'DEPARTMENT NAME', value: auth.departmentName),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: VoucherInfoField(
                label: 'TOTAL LIMIT', value: 'Rs. ${auth.discountLimit.toInt()}')),
            const SizedBox(width: 10),
            Expanded(child: VoucherInfoField(
                label: 'AVAILABLE LIMIT', value: 'Rs. ${(auth.discountLimit - auth.usedLimit).toInt()}')),
          ]),
        ] else ...[
          Row(children: [
            Expanded(child: VoucherInfoField(label: 'DEPARTMENT NAME', value: '')),
            const SizedBox(width: 10),
            Expanded(child: VoucherInfoField(label: 'TOTAL LIMIT', value: '')),
            const SizedBox(width: 10),
            Expanded(child: VoucherInfoField(label: 'AVAILABLE LIMIT', value: '')),
          ]),
        ],
        const SizedBox(height: 10),
        VoucherInfoField(
          label: 'DISCOUNT REASON',
          value: v.discountReason.isEmpty ? '—' : v.discountReason,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        // Discount %Age
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('Discount %Age',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText)),
          const SizedBox(width: 12),
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder)),
            child: Text('${v.discountPercentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
          ),
        ]),
        const SizedBox(height: 6),
        AmountSummaryRow(
            label: 'Discount Amount',
            value: v.discountAmount.toInt().toString()),
        const SizedBox(height: 6),
        AmountSummaryRow(
            label: 'Payable',
            value: v.payable.toInt().toString(),
            isPayable: true,
            isBold: true),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: p.isApproving ? null : () => _showApproveDialog(p),
            icon: p.isApproving 
              ? const CustomLoader(size: 20, color: Colors.white)
              : const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(p.isApproving ? 'Approving...' : 'Approve Discount',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return FadeInUp(
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: kPrimary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('All vouchers approved!',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: kSubText)),
          const SizedBox(height: 8),
          const Text('No pending discount approvals remaining.',
              style: TextStyle(fontSize: 13, color: kSubText)),
        ]),
      ),
    );
  }
}