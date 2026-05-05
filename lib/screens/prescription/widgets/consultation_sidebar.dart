import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/prescription_provider/prescription_provider.dart';
import '../../../custum widgets/custom_loader.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const kTeal = Color(0xFF00B5AD);
const kTealLight = Color(0xFFE0F7F5);
const kBorder = Color(0xFFCCECE9);
const kTextDark = Color(0xFF2D3748);
const kTextMid = Color(0xFF718096);
const kWhite = Colors.white;

class SharedConsultationSidebar extends StatelessWidget {
  final String? department;
  final Function(dynamic)? onSelect;

  const SharedConsultationSidebar({super.key, this.department, this.onSelect});

  String _getWaitTime(dynamic patient) {
    final dateStr = patient['date']?.toString();
    final timeStr = patient['time']?.toString();

    if (timeStr == null || timeStr.isEmpty) return '0m';

    try {
      DateTime receiptDate = dateStr != null
          ? DateTime.parse(dateStr)
          : DateTime.now();

      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final seconds = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

        receiptDate = DateTime(
          receiptDate.year,
          receiptDate.month,
          receiptDate.day,
          hours,
          minutes,
          seconds,
        );
      }

      final now = DateTime.now();
      final diff = now.difference(receiptDate).inMinutes;

      if (diff < 0) return '0m';
      if (diff < 60) return '${diff}m';

      final h = diff ~/ 60;
      final m = diff % 60;
      return '${h}h ${m}m';
    } catch (e) {
      return '0m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    // Filter patients by department if provided
    final filteredPatients = provider.getFilteredConsultationPatients(
      department,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: const LinearGradient(
                colors: [kTeal, Color(0xFF00968F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind, color: kWhite, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Consultation Patients',
                  style: TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: kWhite.withOpacity(0.8),
                    size: 16,
                  ),
                  onPressed: provider.loadConsultationPatients,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  tooltip: 'Refresh Queue',
                ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: provider.isLoadingPatients
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kTeal,
                    ),
                  )
                : filteredPatients.isEmpty
                ? _buildPlaceholder()
                : ListView.separated(
                    itemCount: filteredPatients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final p = filteredPatients[idx];
                      final isPending = p['sync_status'] == 'pending';
                      final waitTime = _getWaitTime(p);
                      final token = p['token_number']?.toString();

                      return ListTile(
                        dense: true,
                        onTap: () {
                          if (onSelect != null) {
                            onSelect!(p);
                          } else {
                            provider.selectConsultationPatient(
                              p,
                              department: department,
                            );
                          }
                        },
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p['patient_name'] ?? 'Unknown Patient',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (token != null) ...[
                              const SizedBox(width: 6),
                              _buildTokenBadge(token),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              p['service_detail'] ?? 'No Service Details',
                              style: const TextStyle(
                                fontSize: 10,
                                color: kTextMid,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 10,
                                  color: Colors.orange.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Wait: $waitTime',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const Spacer(),
                                if (isPending) _buildPendingBadge(),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          p['patient_mr_number']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: kTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenBadge(String token) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kTeal,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '#$token',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 8, color: Colors.orange.shade700),
          const SizedBox(width: 2),
          Text(
            'Pending',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 40, color: kTextMid.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            'No patients in queue',
            style: TextStyle(
              fontSize: 11,
              color: kTextMid.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class SharedConsultationDropdown extends StatelessWidget {
  final String? department;
  final Function(dynamic)? onSelect;

  const SharedConsultationDropdown({super.key, this.department, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPatientSelectionDialog(context, provider);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 20, color: kTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.isLoadingPatients
                        ? 'Loading queue...'
                        : 'Select Consultation Patient',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: kTextMid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPatientSelectionDialog(
    BuildContext context,
    PrescriptionProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: _PatientSelectionDialog(
            department: department,
            onSelect: onSelect,
          ),
        );
      },
    );
  }
}

class _PatientSelectionDialog extends StatefulWidget {
  final String? department;
  final Function(dynamic)? onSelect;

  const _PatientSelectionDialog({this.department, this.onSelect});

  @override
  State<_PatientSelectionDialog> createState() =>
      _PatientSelectionDialogState();
}

class _PatientSelectionDialogState extends State<_PatientSelectionDialog> {
  String _searchQuery = '';

  String _getWaitTime(dynamic patient) {
    final dateStr = patient['date']?.toString();
    final timeStr = patient['time']?.toString();

    if (timeStr == null || timeStr.isEmpty) return '0m';

    try {
      DateTime receiptDate = dateStr != null
          ? DateTime.parse(dateStr)
          : DateTime.now();

      final parts = timeStr.split(':');
      if (parts.isNotEmpty) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final seconds = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

        receiptDate = DateTime(
          receiptDate.year,
          receiptDate.month,
          receiptDate.day,
          hours,
          minutes,
          seconds,
        );
      }

      final now = DateTime.now();
      final diff = now.difference(receiptDate).inMinutes;

      if (diff < 0) return '0m';
      if (diff < 60) return '${diff}m';

      final h = diff ~/ 60;
      final m = diff % 60;
      return '${h}h ${m}m';
    } catch (e) {
      return '0m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final allPatients = provider.getFilteredConsultationPatients(
      widget.department,
    );

    final filteredPatients = _searchQuery.isEmpty
        ? allPatients
        : allPatients.where((p) {
            final name = (p['patient_name'] ?? '').toString().toLowerCase();
            final mr = (p['patient_mr_number'] ?? '').toString().toLowerCase();
            final token = (p['token_number'] ?? '').toString().toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || mr.contains(q) || token.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kTeal, Color(0xFF00968F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      color: kWhite,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Consultation Queue',
                        style: TextStyle(
                          color: kWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kWhite.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: kWhite, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by Name, MR, or Token...',
                    hintStyle: const TextStyle(color: kTextMid, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: kTeal),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // Patient List
              Flexible(
                child: provider.isLoadingPatients
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: kTeal),
                      )
                    : filteredPatients.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: kTextMid.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No patients in queue'
                                  : 'No matches found',
                              style: TextStyle(
                                fontSize: 14,
                                color: kTextMid.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ).copyWith(bottom: 20),
                        shrinkWrap: true,
                        itemCount: filteredPatients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final p = filteredPatients[idx];
                          final token = p['token_number']?.toString();
                          final isPending = p['sync_status'] == 'pending';
                          final waitTime = _getWaitTime(p);

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              if (widget.onSelect != null) {
                                widget.onSelect!(p);
                              } else {
                                provider.selectConsultationPatient(
                                  p,
                                  department: widget.department,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: kTealLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: kTeal.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Token',
                                            style: TextStyle(
                                              color: kTeal,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            token ?? '-',
                                            style: const TextStyle(
                                              color: kTeal,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['patient_name'] ??
                                              'Unknown Patient',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: kTextDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'MR: ${p['patient_mr_number']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: kTeal,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                p['service_detail'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: kTextMid,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 12,
                                              color: Colors.orange.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Wait: $waitTime',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPending)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cloud_off_rounded,
                                            size: 10,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Pending',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.chevron_right,
                                      color: kTextMid,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
