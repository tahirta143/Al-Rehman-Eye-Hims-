import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hims_app/main.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../custum widgets/drawer/base_scaffold.dart';
import '../../providers/pharmacy_provider/pharmacy_provider.dart';
import '../../custum widgets/custom_loader.dart';
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

class PurchasePostingScreen extends StatefulWidget {
  const PurchasePostingScreen({super.key});

  @override
  State<PurchasePostingScreen> createState() => _PurchasePostingScreenState();
}

class _PurchasePostingScreenState extends State<PurchasePostingScreen> {
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _purPriceCtrl = TextEditingController(text: '0');
  final TextEditingController _salePriceCtrl = TextEditingController(text: '0');
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  
  TextEditingController? _activeSearchCtrl;
  Map<String, dynamic>? _selectedMed;
  Map<String, dynamic> _editItem = {};

  bool _isPosting = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PharmacyProvider>(context, listen: false).initBootstrap();
    });
  }

  void _resetEditItem() {
    setState(() {
      _selectedMed = null;
      _activeSearchCtrl?.clear();
      _purPriceCtrl.text = '0';
      _salePriceCtrl.text = '0';
      _qtyCtrl.text = '1';
      _editItem = {};
    });
  }

  void _selectMedicine(dynamic med) {
    setState(() {
      _selectedMed = med;
      // Handle various possible keys for pack size and loose stock
      double packSize = double.tryParse((med['pack_size'] ?? med['pack_quantity'] ?? '1').toString()) ?? 1.0;
      int looseStock = int.tryParse((med['loose_stock'] ?? med['current_stock'] ?? med['current_loose_stock'] ?? '0').toString()) ?? 0;
      
      _editItem = {
        'medicine_id': med['id'],
        'item_name': med['display_name'] ?? med['medicine_name'] ?? med['brand_name'] ?? 'Unknown Item',
        'generic_name': med['generic_name'] ?? '-',
        'manufacturer_name': med['manufacturer_name'] ?? med['manufacturer'] ?? '-',
        'type': med['type_name'] ?? med['category_name'] ?? '-',
        'unit': med['unit'] ?? med['unit_name'] ?? '-',
        'pack_size': packSize,
        'stock_unit': packSize > 0 ? (looseStock / packSize).floor() : 0,
        'current_loose_stock': looseStock,
        'purchase_price': (med['purchase_rate'] ?? med['purchase_price'] ?? med['last_purchase_rate'] ?? '0').toString(),
        'sale_price': (med['sale_rate'] ?? med['sale_price'] ?? med['last_sale_rate'] ?? '0').toString(),
        'quantity': '1',
        'total': (med['purchase_rate'] ?? med['purchase_price'] ?? med['last_purchase_rate'] ?? '0').toString(),
      };
      _purPriceCtrl.text = _editItem['purchase_price'];
      _salePriceCtrl.text = _editItem['sale_price'];
      _qtyCtrl.text = '1';
      _activeSearchCtrl?.clear();
    });
  }

  void _addItem() {
    if (_selectedMed == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    final total = (double.tryParse(_purPriceCtrl.text) ?? 0) * qty;
    
    prov.addPurchaseItem({
      ..._editItem,
      'purchase_price': _purPriceCtrl.text,
      'sale_price': _salePriceCtrl.text,
      'quantity': _qtyCtrl.text,
      'total': total,
    });
    _resetEditItem();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PharmacyProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final headerDate = prov.purchaseHeader['purchase_date'] as DateTime? ?? DateTime.now();

    return BaseScaffold(
      title: 'Purchase Posting',
      drawerIndex: 19,
      actions: [
        IconButton(
          onPressed: _handlePost,
          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
          tooltip: 'Post Purchase',
        ),
      ],
      body: prov.isLoading 
          ? const CustomLoader(color: kTeal)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    child: Column(
                      children: [
                        _buildHeaderSection(prov, headerDate, isMobile),
                        const SizedBox(height: 16),
                        _buildItemAdditionSection(prov, isMobile),
                        const SizedBox(height: 16),
                        _buildPurchaseTable(prov, isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderSection(PharmacyProvider prov, DateTime headerDate, bool isMobile) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]
        ),
        child: Column(
          children: [
            if (isMobile) ...[
              Row(
                children: [
                  Expanded(child: _buildHeaderField('Purchase ID', prov.purchaseHeader['purchase_code'] ?? 'PTR-NEW', enabled: false)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDatePickerField(prov, headerDate)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Supplier', prov.suppliers, prov.purchaseHeader['supplier_id']?.toString(), (v) => prov.updatePurchaseHeader('supplier_id', v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Invoice No', _invoiceNoCtrl, (v) => prov.updatePurchaseHeader('invoice_no', v))),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _buildHeaderField('Purchase ID', prov.purchaseHeader['purchase_code'] ?? 'PTR-NEW', enabled: false)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Invoice No', _invoiceNoCtrl, (v) => prov.updatePurchaseHeader('invoice_no', v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('Supplier', prov.suppliers, prov.purchaseHeader['supplier_id']?.toString(), (v) => prov.updatePurchaseHeader('supplier_id', v))),
                  const SizedBox(width: 12),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _buildDatePickerField(PharmacyProvider prov, DateTime headerDate) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: headerDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) prov.updatePurchaseHeader('purchase_date', picked);
      },
      child: _buildHeaderField('Date', DateFormat('yyyy-MM-dd').format(headerDate), suffixIcon: Icons.calendar_today_outlined),
    );
  }

  Widget _buildItemAdditionSection(PharmacyProvider prov, bool isMobile) {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: kTeal, size: 18),
                const SizedBox(width: 8),
                const Text('PRODUCT SELECTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTeal)),
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
              onSelected: (med) {
                FocusScope.of(context).unfocus();
                _selectMedicine(med);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                _activeSearchCtrl = controller;
                return SizedBox(
                  height: 44,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search products by name or generic...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20, color: kTeal),
                      filled: true,
                      fillColor: kBg.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal, width: 1.5)),
                    ),
                  ),
                );
              },
            ),
            if (_selectedMed != null) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMiniInfo('Type', _editItem['type'] ?? '-')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniInfo('Generic', _editItem['generic_name'] ?? '-')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniInfo('Manufacturer', _editItem['manufacturer_name'] ?? '-')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniInfo('Unit', _editItem['unit'] ?? '-')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMiniInfo('Pack Size', _editItem['pack_size']?.toString() ?? '1')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniInfo('Stock Unit', _editItem['stock_unit']?.toString() ?? '0')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniInfo('Loose Stock', _editItem['current_loose_stock']?.toString() ?? '0')),
                    ],
                  ),
                  const Divider(height: 32, color: kBg),
                  Row(
                    children: [
                      Expanded(child: _buildItemInput('P. Price', _purPriceCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(v) ?? 0) * (double.tryParse(_qtyCtrl.text) ?? 0)))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildItemInput('S. Price', _salePriceCtrl)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildItemInput('Quantity', _qtyCtrl, onChanged: (v) => setState(() => _editItem['total'] = (double.tryParse(_purPriceCtrl.text) ?? 0) * (double.tryParse(v) ?? 0)))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LINE TOTAL', style: TextStyle(fontSize: 9, color: kTextMid, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                              alignment: Alignment.centerLeft,
                              child: Text('Rs. ${double.tryParse(_editItem['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kTeal)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal, 
                    foregroundColor: kWhite, 
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_shopping_cart, size: 18),
                      SizedBox(width: 10),
                      Text('ADD MEDICINE TO LIST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
                ],
              
            ],

        ),
      );
  }

  Widget _buildPurchaseTable(PharmacyProvider prov, bool isMobile) {
    return Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: kHeaderBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 25, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
                  const Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
                  const Expanded(child: Text('UNIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
                  const Expanded(child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
                  const Expanded(child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
                  const SizedBox(width: 35),
                ],
              ),
            ),
            if (prov.purchaseItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: kBg),
                    const SizedBox(height: 12),
                    const Text('No items added yet', style: TextStyle(color: kTextMid, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prov.purchaseItems.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: kBg),
                itemBuilder: (context, index) {
                  final item = prov.purchaseItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 25, child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: kTextMid))),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextDark)),
                              Text(item['generic_name'] ?? '', style: const TextStyle(fontSize: 9, color: kTextMid)),
                            ],
                          ),
                        ),
                        Expanded(child: Text(item['unit']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
                        Expanded(child: Text(item['quantity']?.toString() ?? '0', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text(double.tryParse(item['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kTeal))),
                        SizedBox(
                          width: 35, 
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red), 
                            onPressed: () => prov.removePurchaseItem(index),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            // Inline Summary Section
            if (prov.purchaseItems.isNotEmpty) _buildInlineSummary(prov),
          ],
        ),
      );
  }

  Widget _buildInlineSummary(PharmacyProvider prov) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMid)),
              Text('Rs. ${prov.purchaseSummary['total_amount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMid)),
              SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => prov.updatePurchaseDiscount(double.tryParse(v) ?? 0),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kTeal)),
                    filled: true,
                    fillColor: kWhite,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: kBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PAYABLE AMOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kTextDark)),
              Text('Rs. ${prov.purchaseSummary['payable_amount'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTeal)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cloud_upload_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('POST PURCHASE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter(PharmacyProvider prov, bool isMobile) {
    return const SizedBox.shrink(); // Moved inline
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: DropdownButtonFormField<String>(
            isExpanded: true, // Fixes overflow inside dropdown
            value: (value != null && items.any((i) => i['id'].toString() == value)) ? value : null,
            onChanged: onChanged,
            icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18, color: kTextMid),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal)),
              filled: true,
              fillColor: kWhite,
            ),
            items: items.map((i) => DropdownMenuItem(
              value: i['id'].toString(),
              child: Text(i['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    final displayValue = (value == null || value.isEmpty || value == 'null') ? '-' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            displayValue, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextDark), 
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildItemInput(String label, TextEditingController ctrl, {Function(String)? onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal)),
            filled: true,
            fillColor: kWhite,
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    ]);
  }

  Widget _buildHeaderField(String label, String value, {bool enabled = true, IconData? suffixIcon}) {
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
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark), overflow: TextOverflow.ellipsis)),
              if (suffixIcon != null) Icon(suffixIcon, size: 16, color: kTeal.withOpacity(0.7)),
            ],
          ),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kTeal)),
              filled: true,
              fillColor: kWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isGrand = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isGrand ? 16 : 14, fontWeight: isGrand ? FontWeight.bold : FontWeight.w500, color: isGrand ? kTextDark : kTextMid)),
        Text('Rs. ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: isGrand ? 22 : 15, fontWeight: isGrand ? FontWeight.w900 : FontWeight.bold, color: isGrand ? kTeal : kTextDark)),
      ],
    );
  }

  Future<void> _handlePost() async {
    if (_isPosting) return;
    
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    if (prov.purchaseItems.isEmpty) {
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(content: Text('No items in purchase list'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final res = await prov.savePurchase();
      if (!mounted) return;

      if (res['success'] == true) {
        _showSuccessDialog(res['purchase_code'] ?? '');
        _invoiceNoCtrl.clear();
        _resetEditItem();
      } else {
        snackbarKey.currentState?.hideCurrentSnackBar();
        snackbarKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to post purchase'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        snackbarKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kTealLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: kTeal, size: 60),
            ),
            const SizedBox(height: 20),
            const Text('Success!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 10),
            Text('Purchase posted successfully with ID:', style: TextStyle(color: kTextMid, fontSize: 13)),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTeal)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('GREAT!', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
