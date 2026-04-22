import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/prescription_provider/lab_values_provider.dart';
import '../../../core/utils/date_formatter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/providers/permission_provider.dart';
import '../../../core/permissions/permission_keys.dart';
import '../../../../custum widgets/custom_loader.dart';

class LabValuesSheet extends StatefulWidget {
  final String mrNumber;
  final String? receiptId;
  final bool readOnly;

  const LabValuesSheet({
    super.key,
    required this.mrNumber,
    this.receiptId,
    this.readOnly = false,
  });

  @override
  State<LabValuesSheet> createState() => _LabValuesSheetState();
}

class _LabValuesSheetState extends State<LabValuesSheet> {
  final TextEditingController _paramCtrl = TextEditingController();
  bool _showAddParam = false;
  bool _showAddDate = false;
  DateTime? _selectedDate;

  // Constants for styling (Aligned with OPD Receipt theme)
  static const kTeal = Color(0xFF00B5AD);
  static const kTealLight = Color(0xFFE6F7F6);
  static const kTextDark = Color(0xFF1A202C);
  static const kTextMid = Color(0xFF4A5568);
  static const kTextLight = Color(0xFF718096);
  static const kBorder = Color(0xFFE2E8F0);
  static const kBgLight = Color(0xFFF4F7FA);
  static const kWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LabValuesProvider>().loadLabValues(
        mrNumber: widget.mrNumber,
        receiptId: widget.receiptId,
      );
    });
  }

  @override
  void didUpdateWidget(LabValuesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mrNumber != widget.mrNumber || oldWidget.receiptId != widget.receiptId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LabValuesProvider>().loadLabValues(
              mrNumber: widget.mrNumber,
              receiptId: widget.receiptId,
            );
      });
    }
  }

  @override
  void dispose() {
    _paramCtrl.dispose();
    super.dispose();
  }

  void _onExport() {
    // Basic CSV Export Logic
    final provider = context.read<LabValuesProvider>();
    final sheet = provider.sheet;
    if (sheet.parameters.isEmpty || sheet.dates.isEmpty) return;

    final sortedDates = [...sheet.dates]..sort((a, b) => b.compareTo(a));
    
    StringBuffer csv = StringBuffer();
    csv.write('Measurement Name,');
    csv.writeln(sortedDates.join(','));

    for (var param in sheet.parameters) {
      csv.write('$param,');
      final values = sortedDates.map((d) => sheet.entries[param]?[d] ?? '').join(',');
      csv.writeln(values);
    }

    // Showing a snackbar with the content for now (or could use share package if available)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV logic ready. sharing/saving requires additional packages.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LabValuesProvider>();
    final sheet = provider.sheet;
    final isLoading = provider.isLoading;
    final isSaving = provider.isSaving;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: CustomLoader(color: kTeal,),
      );
    }

    if (widget.mrNumber.isEmpty) {
      return _buildEmptyState('Select a patient first to manage lab values');
    }

    final sortedDates = [...sheet.dates]..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Bar ────────────────────────────────────────────────────
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.flask, size: 14, color: kTeal),
            const SizedBox(width: 8),
            const Text(
              'INVESTIGATION SHEET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: kTextDark,
                letterSpacing: 0.5,
              ),
            ),
            if (isSaving || provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ZoomIn(
                  child: Text(
                    isSaving ? 'Saving...' : 'Save Error',
                    style: TextStyle(
                      fontSize: 10, 
                      color: isSaving ? Colors.orange : Colors.red, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (!widget.readOnly && context.read<PermissionProvider>().canAny([Perm.mrUpdate, Perm.mrCreate, Perm.labCreate])) ...[
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 20, color: kTeal),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final dateStr = picked.toIso8601String().split('T')[0];
                    provider.addDate(dateStr, mrNumber: widget.mrNumber, receiptId: widget.receiptId);
                  }
                },
                tooltip: 'Add Date',
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // ── Investigation Table ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header
              Container(
                color: const Color(0xFF334155), // slate-700
                child: Row(
                  children: [
                    _buildHeaderCell('Measurement Name', width: 200, isLeft: true),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...sortedDates.map((d) => _buildHeaderCell(
                              AppDateFormatter.format(DateTime.parse(d)),
                              width: 120,
                              onDelete: widget.readOnly ? null : () => provider.removeDate(d, mrNumber: widget.mrNumber, receiptId: widget.receiptId),
                            )),
                            if (sortedDates.isEmpty)
                              _buildHeaderCell('No dates added', width: 200, isItalic: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Add Parameter Row (inline)
              if (_showAddParam)
                _buildAddParamRow(provider),

              // Table Body
              if (sheet.parameters.isEmpty)
                _buildEmptyTableState()
              else
                ...sheet.parameters.asMap().entries.map((entry) {
                   final idx = entry.key;
                   final param = entry.value;
                   return _buildDataRow(idx, param, sortedDates, provider);
                }),
            ],
          ),
        ),

        // ── Pagination / Footer ───────────────────────────────────────────
        if (sheet.parameters.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Showing ${sheet.parameters.length} parameters',
              style: const TextStyle(fontSize: 10, color: kTextMid),
            ),
          ),

          const SizedBox(height: 100), // Safety space for scrolling
      ],
    );
  }

  Widget _buildHeaderCell(String text, {double width = 120, bool isLeft = false, bool isItalic = false, VoidCallback? onDelete}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (isLeft && !widget.readOnly && context.read<PermissionProvider>().canAny([Perm.mrUpdate, Perm.mrCreate, Perm.labCreate])) ...[
            GestureDetector(
              onTap: () => setState(() => _showAddParam = !_showAddParam),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 10, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isItalic ? Colors.white38 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
              textAlign: isLeft ? TextAlign.left : TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 12, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(int idx, String param, List<String> dates, LabValuesProvider provider) {
    final isEven = idx % 2 == 0;
    return Container(
      color: isEven ? Colors.transparent : kBgLight,
      child: Row(
        children: [
          // Fixed Left Column
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: kBorder.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    param,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextDark),
                  ),
                ),
                if (!widget.readOnly)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                    onPressed: () => provider.removeParameter(param, mrNumber: widget.mrNumber, receiptId: widget.receiptId),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          // Scrollable Cells
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...dates.map((date) {
                    final val = provider.sheet.entries[param]?[date] ?? '';
                    return _buildCell(param, date, val, provider);
                  }),
                  if (dates.isEmpty) Container(width: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String param, String date, String value, LabValuesProvider provider) {
    return Container(
      width: 120,
      height: 40,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: kBorder.withOpacity(0.3))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.readOnly ? null : () => _editCellValue(param, date, value, provider),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                value.isEmpty ? '—' : value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: value.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                  color: value.isNotEmpty ? kTeal : kTextMid.withOpacity(0.3),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editCellValue(String param, String date, String currentVal, LabValuesProvider provider) {
    final ctrl = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $param', style: const TextStyle(fontSize: 14)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter value',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateCell(param, date, ctrl.text, mrNumber: widget.mrNumber, receiptId: widget.receiptId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kTeal),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddParamRow(LabValuesProvider provider) {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: kTeal.withOpacity(0.05),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paramCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Enter parameter name (e.g. HbA1C)',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onSubmitted: (val) {
                  if (val.isNotEmpty) {
                    provider.addParameter(val, mrNumber: widget.mrNumber, receiptId: widget.receiptId);
                    _paramCtrl.clear();
                    setState(() => _showAddParam = false);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                if (_paramCtrl.text.isNotEmpty) {
                  provider.addParameter(_paramCtrl.text, mrNumber: widget.mrNumber, receiptId: widget.receiptId);
                  _paramCtrl.clear();
                  setState(() => _showAddParam = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kTeal, padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Add'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _showAddParam = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.flask, size: 48, color: kTextMid.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: kTextMid.withOpacity(0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyTableState() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.playlist_add, size: 32, color: kTextMid.withOpacity(0.2)),
          const SizedBox(height: 8),
          const Text('No parameters added yet', style: TextStyle(color: kTextMid, fontSize: 12)),
          if (!widget.readOnly && context.read<PermissionProvider>().canAny([Perm.mrUpdate, Perm.mrCreate, Perm.labCreate]))
            TextButton(
              onPressed: () => setState(() => _showAddParam = true),
              child: const Text('Add a parameter', style: TextStyle(color: kTeal)),
            ),
        ],
      ),
    );
  }
}
