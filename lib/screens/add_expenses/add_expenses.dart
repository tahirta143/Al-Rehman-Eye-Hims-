import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../custum widgets/drawer/base_scaffold.dart';
import '../../models/add_expenses_model/add_expenses_model.dart';
import '../../providers/add_expenses/add_expenses.dart';
import '../../custum widgets/custom_loader.dart';
import '../../providers/shift_management/shift_management.dart';
import '../../models/shift_model/shift_model.dart';
import '../../core/services/auth_storage_service.dart';

const Color _teal = Color(0xFF00B5AD);

class ExpensesScreen extends StatelessWidget {
  final bool useScaffold;
  const ExpensesScreen({super.key, this.useScaffold = true});

  @override
  Widget build(BuildContext context) {
    final shift = context.read<ShiftProvider>().shift;
    final content = ChangeNotifierProvider(
      create: (_) => ExpensesProvider(shiftId: shift?.shiftId),
      child: const _ExpensesBody(),
    );

    if (!useScaffold) return content;

    return BaseScaffold(
      title: 'Expenses',
      drawerIndex: 2,
      showNotificationIcon: false,
      actions: [const SizedBox(width: 8), _RefreshButton()],
      body: content,
    );
  }
}

// ─── Refresh Button ───────────────────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ExpensesProvider>().clearSearch();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Refreshed'),
          backgroundColor: const Color(0xFF00B5AD),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white, size: 15),
            SizedBox(width: 5),
            Text('Refresh',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _ExpensesBody extends StatelessWidget {
  const _ExpensesBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpensesProvider>();
    final sw = MediaQuery.of(context).size.width;

    return Container(
      color: const Color(0xFFF0F4F8),
      child: provider.isLoading
          ? const Center(
              child: CustomLoader(
                size: 50,
                color: _teal,
              ),
            )
          : provider.errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 48),
            const SizedBox(height: 12),
            Text(provider.errorMessage!,
                style: const TextStyle(color: Color(0xFF718096))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final shift = context.read<ShiftProvider>().shift;
                context.read<ExpensesProvider>().fetchExpenses(shiftId: shift?.shiftId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B5AD),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => provider.fetchExpenses(),
        color: _teal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  sw < 400 ? 10 : 16, sw < 400 ? 10 : 16, sw < 400 ? 10 : 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PageHeader(),
                  SizedBox(height: sw > 800 ? 18 : 14),
                  if (sw > 800)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _TotalExpensesCard()),
                        const SizedBox(width: 14),
                        _AddExpenseCard(),
                      ],
                    )
                  else
                    Column(children: [
                      _TotalExpensesCard(),
                      const SizedBox(height: 12),
                    ]),
                  SizedBox(height: sw > 800 ? 16 : 12),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    sw < 400 ? 10 : 16, 0, sw < 400 ? 10 : 16, sw < 400 ? 10 : 16),
                child: const _RecentTransactionsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isTablet = sw > 600;
    final isDesktop = sw > 800;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 12 : isTablet ? 10 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00B5AD).withOpacity(0.12),
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
          ),
          child: Icon(Icons.account_balance_wallet_outlined,
              color: const Color(0xFF00B5AD),
              size: isDesktop ? 28 : isTablet ? 24 : 20),
        ),
        SizedBox(width: (sw * 0.03).clamp(8, 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: (sw * 0.03).clamp(20, isDesktop ? 50.0 : isTablet ? 45.0 : 40.0),
                children: [
                  Text('Add Expenses',
                      style: TextStyle(
                          fontSize: isDesktop ? 24 : isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C))),
                  _AddExpenseCard(),
                ],
              ),
              SizedBox(height: sh * 0.005),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Total Expenses Card ──────────────────────────────────────────────────────
class _TotalExpensesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = context.watch<ExpensesProvider>().formattedTotal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(bottom: BorderSide(color: Color(0xFF00B5AD), width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SHIFT TOTAL EXPENSES',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF718096),
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Text(total,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00B5AD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF00B5AD), size: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Card ─────────────────────────────────────────────────────────
class _AddExpenseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00B5AD),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00B5AD).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Add Expense',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) {
    final shift = context.read<ShiftProvider>().shift;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExpensesProvider>(),
        child: _ExpenseDialog(
          shiftId: shift?.shiftId,
          shiftDate: shift?.shiftDate,
          shiftType: shift?.shiftType,
        ),
      ),
    );
  }
}

// ─── Unified Add / Edit Dialog ────────────────────────────────────────────────
class _ExpenseDialog extends StatefulWidget {
  final ExpenseModel? expense; // null = Add mode, non-null = Edit mode
  final int? shiftId;
  final String? shiftDate;
  final String? shiftType;

  const _ExpenseDialog({
    this.expense,
    this.shiftId,
    this.shiftDate,
    this.shiftType,
  });

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _expenseByCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  bool _isSaving = false;

  bool get _isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpensesProvider>();
    final heads = provider.expenseHeads;
    
    // Pre-fill fields if editing
    _amountCtrl = TextEditingController(
        text: _isEditMode ? widget.expense!.amount.toStringAsFixed(2) : '');
    
    // Default user name from auth context if available (handled in initState or build is easier)
    _expenseByCtrl = TextEditingController(
        text: _isEditMode ? widget.expense!.expenseBy : '');

    _descCtrl = TextEditingController(
        text: _isEditMode ? widget.expense!.description : '');
    
    _category = _isEditMode
        ? (heads.contains(widget.expense!.category)
            ? widget.expense!.category
            : (heads.isNotEmpty ? heads.first : ''))
        : (heads.isNotEmpty ? heads.first : '');
    
    // Shift is now automated, removing _shift controller/variable
    
    if (!_isEditMode) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final storage = AuthStorageService();
    final fullName = await storage.getFullName();
    final username = await storage.getUsername();
    if (mounted) {
      setState(() {
        _expenseByCtrl.text = fullName ?? username ?? '';
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _expenseByCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final provider = context.read<ExpensesProvider>();
    bool success;

    if (_isEditMode) {
      // ── UPDATE ──────────────────────────────────────────────────────
      success = await provider.updateExpense(
        srlNo: widget.expense!.srlNo,
        category: _category,
        amount: double.parse(_amountCtrl.text.trim()),
        expenseBy: _expenseByCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        expenseShift: widget.expense!.expenseShift, // Keep original shift on edit
        expenseDate: widget.expense!.expenseDate,
        expenseTime: widget.expense!.expenseTime,
      );
    } else {
      // ── CREATE ──────────────────────────────────────────────────────
      success = await provider.addExpense(
        category: _category,
        amount: double.parse(_amountCtrl.text.trim()),
        expenseBy: _expenseByCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        shiftId: widget.shiftId,
        shiftDate: widget.shiftDate,
        expenseShift: widget.shiftType,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Expense updated successfully!' : 'Expense saved successfully!'),
          ]),
          backgroundColor: _teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(_isEditMode ? 'Failed to update expense.' : 'Failed to save expense.'),
          ]),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width < 500 ? 16 : 40,
          vertical: 24),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B5AD).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditMode ? Icons.edit_outlined : Icons.add_card_outlined,
                      color: const Color(0xFF00B5AD),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode ? 'Edit Expense' : 'Add New Expense',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A202C)),
                        ),
                        Text(
                          _isEditMode
                              ? 'Update expense #${widget.expense!.id}'
                              : 'Record a new transaction',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF718096)),
                  ),
                ]),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF0F0F0)),
                const SizedBox(height: 16),

                // ── Category ─────────────────────────────────────────────
                _lbl('Expense Category / Name', required: true),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _category,
                  isExpanded: true,
                  hint: const Text('Select Expense Head', style: TextStyle(fontSize: 14)),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
                  decoration: _deco(icon: Icons.description_outlined),
                  items: context.watch<ExpensesProvider>().expenseHeads
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // ── Amount ────────────────────────────────────────────────
                _lbl('Amount (PKR)', required: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 14),
                  decoration: _deco(hint: '0.00', icon: Icons.calculate_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    if (double.parse(v.trim()) <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Expense By ────────────────────────────────────────────
                _lbl('Expense By', required: true),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _expenseByCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: _deco(icon: Icons.person_outline),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Description ───────────────────────────────────────────
                _lbl('Description / Remarks'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add more details about this expense...',
                    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF00B5AD), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save / Update Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const Center(
                            child: CustomLoader(
                              size: 20,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isEditMode
                        ? Icons.save_outlined
                        : Icons.check_circle_outline,
                        size: 18),
                    label: Text(
                      _isSaving
                          ? (_isEditMode ? 'Updating...' : 'Saving...')
                          : (_isEditMode ? 'Update Expense' : 'Save Expense'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditMode
                          ? const Color(0xFF4A90D9)
                          : const Color(0xFF00B5AD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lbl(String t, {bool required = false}) => RichText(
    text: TextSpan(
      text: t,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4A5568)),
      children: required
          ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE53E3E)))]
          : [],
    ),
  );

  InputDecoration _deco({String hint = '', IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
    prefixIcon:
    icon != null ? Icon(icon, color: const Color(0xFFCBD5E0), size: 18) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00B5AD), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53E3E))),
    filled: true,
    fillColor: Colors.white,
  );
}

// ─── Recent Transactions Card ─────────────────────────────────────────────────
class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: MediaQuery.of(context).size.width < 700
                ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_title(), const SizedBox(height: 12), _SearchBar()])
                : Row(children: [
              Expanded(child: _title()),
              const SizedBox(width: 16),
              SizedBox(width: 240, child: _SearchBar()),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const _TableHeader(),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const Expanded(child: _TransactionList()),
        ],
      ),
    );
  }

  Widget _title() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent Transactions',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
      SizedBox(height: 2),
    ],
  );
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: (v) {
        setState(() {});
        context.read<ExpensesProvider>().setSearchQuery(v);
      },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search expenses...',
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFBDBDBD), size: 18),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFFBDBDBD), size: 16),
          onPressed: () {
            _ctrl.clear();
            setState(() {});
            context.read<ExpensesProvider>().clearSearch();
          },
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00B5AD), width: 1.5)),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        _h('EXPENSE DETAILS', flex: 4),
        _h('AMOUNT', flex: 2),
        if (MediaQuery.of(context).size.width >= 700) _h('RECORDED BY', flex: 3),
        _h('ACTIONS', flex: 2, center: true), // ← flex 2 to fit both buttons
      ]),
    );
  }

  Widget _h(String t, {int flex = 1, bool center = false}) => Expanded(
    flex: flex,
    child: Text(t,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF718096),
            letterSpacing: 0.5)),
  );
}

// ─── Transaction List ─────────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpensesProvider>().expenses;

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No expenses found',
                style:
                TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: expenses.length,
      itemBuilder: (_, i) =>
          _TransactionRow(expense: expenses[i], isEven: i % 2 == 0),
    );
  }
}

// ─── Transaction Row ──────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final ExpenseModel expense;
  final bool isEven;

  const _TransactionRow({required this.expense, required this.isEven});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Expense Details ──────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A202C))),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.access_time, size: 11, color: Color(0xFF718096)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(expense.formattedTime,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (expense.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(expense.description,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFA0AEC0)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ],
            ),
          ),

          // ── Amount ──────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Text(expense.formattedAmount,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C))),
          ),

          // ── Recorded By ─────────────────────────────────────────────
          if (MediaQuery.of(context).size.width >= 700)
            Expanded(
              flex: 3,
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B5AD).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      expense.expenseBy.isNotEmpty
                          ? expense.expenseBy[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B5AD)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(expense.expenseBy,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568)),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),

          // ── Edit + Delete Buttons ────────────────────────────────────
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Edit button
                GestureDetector(
                  onTap: () => _edit(context, expense),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF4A90D9), size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                GestureDetector(
                  onTap: () => _del(context, expense),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE53E3E), size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Open Edit Dialog ─────────────────────────────────────────────────────
  void _edit(BuildContext context, ExpenseModel e) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExpensesProvider>(),
        child: _ExpenseDialog(expense: e), // ← pass expense = edit mode
      ),
    );
  }

  // ── Delete Confirmation ──────────────────────────────────────────────────
  void _del(BuildContext context, ExpenseModel e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Expense?'),
        content: Text(
            'Remove ${e.category} — ${e.formattedAmount}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
              await context.read<ExpensesProvider>().deleteExpense(e.srlNo);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Failed to delete expense. Please try again.'),
                  backgroundColor: const Color(0xFFE53E3E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}