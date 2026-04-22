import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../custum widgets/drawer/base_scaffold.dart';
import '../../providers/pharmacy_provider/pharmacy_provider.dart';
import '../../providers/mr_provider/mr_provider.dart';
import '../../models/mr_model/mr_patient_model.dart';
import '../../custum widgets/custom_loader.dart';
import '../../core/services/pharmacy_printing_service.dart';
import '../../custum widgets/animations/animations.dart';
import 'package:animate_do/animate_do.dart';

// --- Constants ---
const kTeal = Color(0xFF00B5AD);
const kTealLight = Color(0xFFE0F7F5);
const kBorder = Color(0xFFCCECE9);
const kBg = Color(0xFFF8F9FA);
const kTextDark = Color(0xFF2D3748);
const kTextMid = Color(0xFF718096);
const kWhite = Colors.white;
const kHeaderBg = Color(0xFFF1F5F9);
const kBlue = Color(0xFF2563EB);
const kSuccess = Color(0xFF10B981);
const kAmber = Color(0xFFD97706);
const kAmberLight = Color(0xFFFFFBEB);

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  final FocusNode _mrFocusNode = FocusNode();
  final TextEditingController _medNoCtrl = TextEditingController();
  final TextEditingController _opdNoCtrl = TextEditingController();
  final TextEditingController _customerNameCtrl = TextEditingController(text: 'WALKING CUSTOMER');
  
  final TextEditingController _priceCtrl = TextEditingController(text: '0');
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _discountPercentCtrl = TextEditingController(text: '0');
  final TextEditingController _discountAmountCtrl = TextEditingController(text: '0');
  final TextEditingController _amountGivenCtrl = TextEditingController();
  
  Map<String, dynamic>? _selectedMed;
  Map<String, dynamic> _editItem = {};

  @override
  void initState() {
    super.initState();
    _mrFocusNode.addListener(_onMrBlur);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<PharmacyProvider>(context, listen: false);
      prov.initBootstrap();
      prov.startClock();
    });
  }

  @override
  void dispose() {
    _mrFocusNode.removeListener(_onMrBlur);
    _mrFocusNode.dispose();
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    prov.stopClock();
    _medNoCtrl.dispose();
    _opdNoCtrl.dispose();
    _customerNameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _discountPercentCtrl.dispose();
    _discountAmountCtrl.dispose();
    _amountGivenCtrl.dispose();
    super.dispose();
  }

  void _onMrBlur() {
    if (!_mrFocusNode.hasFocus && _medNoCtrl.text.isNotEmpty) {
      _padAndSearchMR();
    }
  }

  void _padAndSearchMR() {
    final v = _medNoCtrl.text.trim();
    if (v.isEmpty) return;
    
    final padded = v.padLeft(5, '0');
    if (_medNoCtrl.text != padded) {
      _medNoCtrl.text = padded;
    }
    
    _handleMrSearch(padded);
  }

  void _resetEditItem() {
    setState(() {
      _selectedMed = null;
      _priceCtrl.text = '0';
      _qtyCtrl.text = '1';
      _editItem = {};
    });
  }

  void _selectMedicine(dynamic med) {
    final price = med['sale_price'] ?? med['purchase_price'] ?? '0';
    setState(() {
      _selectedMed = med;
      _editItem = {
        'medicine_id': med['id'],
        'item_name': med['display_name'] ?? med['medicine_name'],
        'price': price.toString(),
        'qty': '1',
        'total': price.toString(),
        'in_stock_before': med['loose_stock'] ?? 0,
        'require_purchase': (double.tryParse(med['loose_stock']?.toString() ?? '0') ?? 0) < 1,
      };
      _priceCtrl.text = _editItem['price'];
      _qtyCtrl.text = '1';
    });
  }
  void _addItem() {
    if (_selectedMed == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    final total = (double.tryParse(_priceCtrl.text) ?? 0) * qty;
    
    prov.addSalesItem({
      ..._editItem,
      'price': _priceCtrl.text,
      'qty': _qtyCtrl.text,
      'total': total,
    });
    _resetEditItem();
  }

  Future<void> _handleMrSearch(String mr) async {
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    final mrProv = Provider.of<MrProvider>(context, listen: false);
    
    final patient = await mrProv.findByMrNumber(mr);
    if (patient != null) {
      final opd = (patient.visitHistory != null && patient.visitHistory!.isNotEmpty) 
          ? (patient.visitHistory!.first.receiptId ?? '') 
          : '';
          
      prov.updateSalesHeader('medical_no', patient.mrNumber);
      prov.updateSalesHeader('customer_name', patient.fullName);
      prov.updateSalesHeader('opd_no', opd);
      
      // Update controllers immediately upon search success
      _medNoCtrl.text = patient.mrNumber;
      _customerNameCtrl.text = patient.fullName;
      _opdNoCtrl.text = opd;
    } else {
      prov.updateSalesHeader('medical_no', mr);
      prov.updateSalesHeader('customer_name', 'WALKING CUSTOMER');
      prov.updateSalesHeader('opd_no', '');
      _customerNameCtrl.text = 'WALKING CUSTOMER';
      _opdNoCtrl.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PharmacyProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 900;

    return BaseScaffold(
      title: 'Sales Invoice',
      drawerIndex: 18,
      body: prov.isLoading 
          ? const CustomLoader(color: kTeal)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildHeaderSection(prov, isMobile),
                        const SizedBox(height: 16),
                        _buildItemInputSection(prov, isMobile),
                        const SizedBox(height: 16),
                        _buildBucketSection(prov, isMobile),
                        const SizedBox(height: 16),
                        _buildSummarySection(prov),
                        const SizedBox(height: 24),
                        _buildFooterLists(prov, isMobile),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showSuccessDialog(String receiptNo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Sale Finalized', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invoice has been saved successfully.', style: TextStyle(color: kTextMid)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Receipt No:', style: TextStyle(fontWeight: FontWeight.bold, color: kTextDark)),
                  Text(receiptNo, style: const TextStyle(fontWeight: FontWeight.w900, color: kTeal, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(PharmacyProvider prov, bool isMobile) {
    // Only set initial values if controllers are empty to avoid resetting user input
    if (_medNoCtrl.text.isEmpty && prov.salesHeader['medical_no'].toString().isNotEmpty) {
      _medNoCtrl.text = prov.salesHeader['medical_no'] ?? '';
    }
    if (_customerNameCtrl.text == 'WALKING CUSTOMER' && prov.salesHeader['customer_name'] != 'WALKING CUSTOMER') {
      _customerNameCtrl.text = prov.salesHeader['customer_name'] ?? 'WALKING CUSTOMER';
    }
    
    final headerDate = prov.salesHeader['invoice_date'] as DateTime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: kTeal, size: 18),
              const SizedBox(width: 8),
              const Text('INVOICE HEADER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTeal)),
            ],
          ),
          const SizedBox(height: 20),
          if (isMobile) ...[
            Row(
              children: [
                Expanded(child: _buildHeaderField('Receipt No', prov.salesHeader['receipt_no'] ?? '-', enabled: false)),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kTeal.withValues(alpha: 0.2))),
                  alignment: Alignment.center,
                  child: Text(DateFormat('yyyy-MM-dd').format(headerDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTeal)),
                )),
              ],
            ),
            const SizedBox(height: 16),
            _buildMRSearchField(prov),
            const SizedBox(height: 16),
            _buildTextField('OPD No', _opdNoCtrl, (v) => prov.updateSalesHeader('opd_no', v)),
            const SizedBox(height: 16),
            _buildTextField('Patient Name', _customerNameCtrl, (v) => prov.updateSalesHeader('customer_name', v)),
            const SizedBox(height: 16),
            _buildPrescribedPatientDropdown(prov),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildHeaderField('Receipt No', prov.salesHeader['receipt_no'] ?? '-', enabled: false)),
                const SizedBox(width: 12),
                Expanded(child: _buildMRSearchField(prov)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('OPD No', _opdNoCtrl, (v) => prov.updateSalesHeader('opd_no', v))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField('Patient Name', _customerNameCtrl, (v) => prov.updateSalesHeader('customer_name', v))),
                const SizedBox(width: 12),
                Expanded(child: _buildPrescribedPatientDropdown(prov)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMRSearchField(PharmacyProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MR NO.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: _medNoCtrl,
            focusNode: _mrFocusNode,
            onSubmitted: (v) => _padAndSearchMR(),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Enter MR Number (e.g. 1)',
              hintStyle: const TextStyle(fontSize: 12, color: kTextMid),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
              filled: true,
              fillColor: kBg,
              prefixIcon: prov.isSearchingPatient 
                ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal)))
                : const Icon(Icons.search, size: 18, color: kTeal),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescribedPatientDropdown(PharmacyProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRESCRIBED PATIENTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), 
            border: Border.all(color: kBorder), 
            color: kWhite
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              hint: const Text('Select Prescription', style: TextStyle(fontSize: 12, color: kTextMid)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18, color: kTextMid),
              items: prov.prescribedPatients.map((p) {
                return DropdownMenuItem<int>(
                  value: p['prescription_id'],
                  child: Text('${p['patient_name']} (${p['mr_number']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) prov.handleUsePrescribedPatient(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSaleToggle(PharmacyProvider prov) {
    final isCard = prov.salesHeader['card_sale'] == true;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: InkWell(
        onTap: () => prov.updateSalesHeader('card_sale', !isCard),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYMENT VIA CARD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextDark)),
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: isCard,
                  onChanged: (v) => prov.updateSalesHeader('card_sale', v),
                  activeColor: kTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemInputSection(PharmacyProvider prov, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kTeal.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: kTeal.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: kTeal, size: 20),
              const SizedBox(width: 8),
              const Text('SEARCH MEDICINE', style: TextStyle(fontWeight: FontWeight.bold, color: kTeal, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => option['display_name'] ?? option['medicine_name'] ?? '',
            optionsBuilder: (textEditingValue) async {
              if (textEditingValue.text.length < 2) return const Iterable<Map<String, dynamic>>.empty();
              final res = await prov.searchMedicines(textEditingValue.text);
              return List<Map<String, dynamic>>.from(res['data'] ?? []);
            },
            onSelected: _selectMedicine,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return SizedBox(
                height: 40,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Search products by name or generic...',
                    hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: kTextMid),
                    prefixIcon: const Icon(Icons.search, size: 18, color: kTeal),
                    suffixIcon: controller.text.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { controller.clear(); _resetEditItem(); }) 
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
                    filled: true,
                    fillColor: kWhite,
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: isMobile ? MediaQuery.of(context).size.width - 72 : 500,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final stock = double.tryParse(option['loose_stock']?.toString() ?? '0') ?? 0;
                        return ListTile(
                          title: Text(option['display_name'] ?? option['medicine_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Pkg: ${option['unit'] ?? ''} | Price: Rs.${option['sale_price'] ?? option['purchase_price'] ?? 0}', style: const TextStyle(fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: stock < 1 ? Colors.red.withOpacity(0.1) : kTealLight, borderRadius: BorderRadius.circular(6)),
                            child: Text('Stock: $stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: stock < 1 ? Colors.red : kTeal)),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (_selectedMed != null) ...[
            const SizedBox(height: 20),
            if (isMobile) ...[
              _buildItemInput('Price', _priceCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(v) ?? 0) * (double.tryParse(_qtyCtrl.text) ?? 0))),
              const SizedBox(height: 12),
              _buildItemInput('Quantity', _qtyCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(_priceCtrl.text) ?? 0) * (double.tryParse(v) ?? 0))),
              const SizedBox(height: 16),
              _buildStockIndicator(),
              const SizedBox(height: 20),
              _buildLineTotalRow(),
              const SizedBox(height: 16),
              _buildAddButton(),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _buildItemInput('Price', _priceCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(v) ?? 0) * (double.tryParse(_qtyCtrl.text) ?? 0)))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildItemInput('Quantity', _qtyCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(_priceCtrl.text) ?? 0) * (double.tryParse(v) ?? 0)))),
                  const SizedBox(width: 12),
                  _buildStockIndicator(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLineTotalRow()),
                  const SizedBox(width: 12),
                  _buildAddButton(),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStockIndicator() {
    final bool reqPurchase = _editItem['require_purchase'] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STOCK (${_editItem['in_stock_before'] ?? 0})', style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: reqPurchase ? kAmberLight : kTealLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: reqPurchase ? kAmber.withValues(alpha: 0.3) : kTeal.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(reqPurchase ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 14, color: reqPurchase ? kAmber : kTeal),
              const SizedBox(width: 4),
              Text(reqPurchase ? 'Req. Prch' : 'In Stock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: reqPurchase ? kAmber : kTeal)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineTotalRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('LINE TOTAL', style: TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
          alignment: Alignment.centerLeft,
          child: Text('Rs. ${double.tryParse(_editItem['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kTeal)),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: _addItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: kTeal,
          foregroundColor: kWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_shopping_cart, size: 16),
            SizedBox(width: 8),
            Text('ADD MEDICINE TO LIST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketSection(PharmacyProvider prov, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_basket_outlined, color: kTeal, size: 20),
                const SizedBox(width: 8),
                Text('BUCKET (${prov.salesItems.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal, letterSpacing: 0.5)),
              ],
            ),
          ),
          if (prov.salesItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 48, color: kBorder),
                    const SizedBox(height: 12),
                    const Text('Your bucket is empty', style: TextStyle(color: kTextMid, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prov.salesItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: kBg),
              itemBuilder: (context, index) {
                final item = prov.salesItems[index];
                final bool reqPrch = item['require_purchase'] == true;
                return FadeInUp(
                  duration: Duration(milliseconds: 100 + (index * 50)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Row(
                      children: [
                        Expanded(child: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark))),
                        if (reqPrch)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: kAmberLight, borderRadius: BorderRadius.circular(4)),
                            child: const Text('PURCHASE REQ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: kAmber)),
                          ),
                      ],
                    ),
                    subtitle: Text('Qty: ${item['qty']} @ Rs. ${double.tryParse(item['price'].toString())?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: kTextMid)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rs. ${double.tryParse(item['total'].toString())?.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: kTeal)),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 16), 
                          onPressed: () => prov.removeSalesItem(index),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(PharmacyProvider prov) {
    // Action Buttons Row (Parity with Purchase Posting layout but for Sales)
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: kHeaderBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: kBorder)),
                ),
                child: Column(
                  children: [
                    _buildCardSaleToggle(prov),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildTotalColumn('Gross Total', prov.salesSummary['total_price']),
                        const SizedBox(width: 12),
                        _buildTotalColumn('Payable Amount', prov.salesSummary['payable'], isHighlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildSummaryField('Disc %', _discountPercentCtrl, (v) => prov.updateSalesDiscountPercent(double.tryParse(v) ?? 0))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryField('Disc Amt', _discountAmountCtrl, (v) => prov.updateSalesDiscountAmount(double.tryParse(v) ?? 0))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryField('Paid', _amountGivenCtrl, (v) {
                          prov.updateSalesAmountGiven(double.tryParse(v) ?? 0);
                        }, isHighlighted: true)),
                      ],
                    ),
                    const Divider(height: 32, color: kBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('RETURN AMOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextMid)),
                        Text('Rs. ${prov.salesSummary['return_amount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kSuccess)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _resetSales(prov),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('NEW'),
                style: ElevatedButton.styleFrom(backgroundColor: kTextMid, foregroundColor: kWhite, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleHold(prov),
                icon: const Icon(Icons.pause, size: 18),
                label: const Text('HOLD'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: kWhite, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleFinalize(prov),
                icon: const Icon(Icons.save, size: 18),
                label: Text(prov.salesHeader['id'] != null ? 'FINALIZE' : 'SAVE'),
                style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: kWhite, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
        if (prov.salesHeader['id'] != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDelete(prov),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('DELETE HELD'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: kWhite, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {}, // Print logic
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('PRINT'),
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: kWhite, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _resetSales(PharmacyProvider prov) {
    prov.initBootstrap(); // This resets state in your provider usually, or add a dedicated reset method
    _medNoCtrl.clear();
    _opdNoCtrl.clear();
    _customerNameCtrl.text = 'WALKING CUSTOMER';
    _amountGivenCtrl.clear();
    _discountPercentCtrl.text = '0';
    _discountAmountCtrl.text = '0';
  }

  void _handleHold(PharmacyProvider prov) async {
    if (await prov.holdSale()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale held successfully'), backgroundColor: kSuccess));
      _resetSales(prov);
    }
  }

  void _handleFinalize(PharmacyProvider prov) async {
    if (await prov.finalizeSale()) {
      _showSuccessDialog(prov.salesHeader['receipt_no']);
      _resetSales(prov);
    } else if (prov.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prov.errorMessage!), backgroundColor: Colors.red));
    }
  }

  void _handleDelete(PharmacyProvider prov) async {
    if (prov.salesHeader['id'] == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Confirm'),
      content: const Text('Delete this held invoice?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirmed == true) {
      if (await prov.deleteHeldSale(prov.salesHeader['id'])) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Held sale deleted')));
        _resetSales(prov);
      }
    }
  }

  void _handleDirectDelete(PharmacyProvider prov, int id) async {
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text('Are you sure you want to delete this held invoice?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirmed == true) {
      if (await prov.deleteHeldSale(id)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Held invoice deleted')));
      }
    }
  }

  Widget _buildFooterLists(PharmacyProvider prov, bool isMobile) {
    return Column(
      children: [
        _buildInvoiceList(prov, 'Held Invoices', prov.heldInvoices, Colors.orange, (inv) => prov.resumeHeldSale(inv['id'])),
        const SizedBox(height: 16),
        _buildInvoiceList(prov, 'Recent Invoices', prov.recentInvoices, kTeal, null),
      ],
    );
  }

  Widget _buildInvoiceList(PharmacyProvider prov, String title, List<dynamic> list, Color themeColor, Function(dynamic)? onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark.withOpacity(0.8))),
            const Spacer(),
            Text('${list.length} Records', style: TextStyle(fontSize: 10, color: kTextMid)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
          child: list.isEmpty 
              ? Center(child: Text('No $title found', style: const TextStyle(fontSize: 11, color: kTextMid)))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final inv = list[index];
                    final bool isHeldList = title.contains('Held');
                    return InkWell(
                      onTap: onTap != null ? () => onTap(inv) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorder.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv['receipt_no'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeColor)),
                                SizedBox(
                                  width: 120, // Limit width for name
                                  child: Text(inv['customer_name'] ?? 'Walking Customer', style: const TextStyle(fontSize: 11, color: kTextMid), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text('Rs. ${inv['payable_amount'] ?? inv['total_amount'] ?? 0}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kTextDark)),
                            const SizedBox(width: 8),
                            if (isHeldList) 
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _handleDirectDelete(prov, inv['id']),
                                visualDensity: VisualDensity.compact,
                              )
                            else 
                              Icon(Icons.chevron_right, size: 16, color: kTextMid),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPrescribedPatientsSidebar(PharmacyProvider prov) {
    return Container(
      color: kBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: kTeal,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people_outline, color: kWhite, size: 20),
                    SizedBox(width: 8),
                    Text('Prescribed Patients', style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  ],
                ),
                if (prov.isLoadingPrescribedPatients || prov.isApplyingPrescription)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kWhite))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: kWhite, size: 18),
                    onPressed: prov.loadPrescribedPatients,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: prov.isLoadingPrescribedPatients && prov.prescribedPatients.isEmpty
                ? const Center(child: CustomLoader(color: kTeal))
                : prov.prescribedPatients.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: kBorder),
                          const SizedBox(height: 12),
                          const Text('No prescriptions found', style: TextStyle(fontSize: 12, color: kTextMid)),
                        ],
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: prov.prescribedPatients.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final p = prov.prescribedPatients[index];
                          return FadeInRight(
                            duration: Duration(milliseconds: 200 + (index * 50)),
                            child: InkWell(
                              onTap: prov.isApplyingPrescription ? null : () => prov.handleUsePrescribedPatient(p['prescription_id']),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorder),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p['mr_number'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTeal, fontFamily: 'monospace')),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(4)),
                                          child: Text('${p['medicines_count']} meds', style: const TextStyle(fontSize: 9, color: kTeal, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p['patient_name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('OPD: ${p['opd_no'] ?? '-'} | Dr. ${p['doctor_name'] ?? '-'}', style: const TextStyle(fontSize: 10, color: kTextMid), overflow: TextOverflow.ellipsis),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.withOpacity(0.5)),
                                        onPressed: () => prov.deletePrescribedPatient(p['prescription_id']),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Remove',
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildHeaderField(String label, String value, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? kWhite : kBg, 
            border: Border.all(color: enabled ? kBorder : kBg), 
            borderRadius: BorderRadius.circular(10)
          ),
          alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
            decoration: InputDecoration(
              isDense: true, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
              filled: true,
              fillColor: kWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemInput(String label, TextEditingController ctrl, {Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
              filled: true,
              fillColor: kWhite,
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryField(String label, TextEditingController ctrl, Function(String) onChanged, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: ctrl,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true, 
              filled: true,
              fillColor: kWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalColumn(String label, double value, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isHighlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          Text('Rs. ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: isHighlight ? 22 : 16, fontWeight: FontWeight.w900, color: isHighlight ? kTeal : kTextDark)),
        ],
      ),
    );
  }
}
