import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../custum widgets/drawer/base_scaffold.dart';
import '../../providers/pharmacy_provider/pharmacy_provider.dart';
import '../../custum widgets/custom_loader.dart';

// --- Constants ---
const kTeal = Color(0xFF00B5AD);
const kTealLight = Color(0xFFE0F7F5);
const kBorder = Color(0xFFCCECE9);
const kBg = Color(0xFFF8F9FA);
const kTextDark = Color(0xFF2D3748);
const kTextMid = Color(0xFF718096);
const kWhite = Colors.white;
const kHeaderBg = Color(0xFFF1F5F9);
const kBlue = Color(0xFF2563EB); // React blue

class AddModifyMedicinesScreen extends StatefulWidget {
  const AddModifyMedicinesScreen({super.key});

  @override
  State<AddModifyMedicinesScreen> createState() => _AddModifyMedicinesScreenState();
}

class _AddModifyMedicinesScreenState extends State<AddModifyMedicinesScreen> {
  
  // Form Controllers
  final TextEditingController _brandNameCtrl = TextEditingController();
  final TextEditingController _strengthCtrl = TextEditingController();
  final TextEditingController _genericNameCtrl = TextEditingController();
  final TextEditingController _displayNameCtrl = TextEditingController();
  final TextEditingController _packQtyCtrl = TextEditingController(text: '1');
  final TextEditingController _maxDiscountCtrl = TextEditingController(text: '0');
  final TextEditingController _reorderLevelCtrl = TextEditingController(text: '0');
  
  int? _editingId;
  String? _categoryId;
  String? _supplierId;
  String? _manufacturerId;
  String? _packSizeId;
  String? _shelfLocationId;
  
  bool _isControlled = false;
  bool _stopSale = false;
  bool _isCostly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<PharmacyProvider>(context, listen: false);
      prov.initBootstrap();
      prov.loadMedicines();
    });
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _brandNameCtrl.clear();
      _strengthCtrl.clear();
      _genericNameCtrl.clear();
      _displayNameCtrl.clear();
      _packQtyCtrl.text = '1';
      _maxDiscountCtrl.text = '0';
      _reorderLevelCtrl.text = '0';
      _categoryId = null;
      _supplierId = null;
      _manufacturerId = null;
      _packSizeId = null;
      _shelfLocationId = null;
      _isControlled = false;
      _stopSale = false;
      _isCostly = false;
    });
  }

  void _fillForm(dynamic med) {
    setState(() {
      _editingId = med['id'];
      _brandNameCtrl.text = med['brand_name'] ?? '';
      _strengthCtrl.text = med['strength'] ?? '';
      _genericNameCtrl.text = med['generic_name'] ?? '';
      _displayNameCtrl.text = med['display_name'] ?? med['medicine_name'] ?? '';
      _packQtyCtrl.text = (med['pack_quantity'] ?? '1').toString();
      _maxDiscountCtrl.text = (med['max_discount_pct'] ?? '0').toString();
      _reorderLevelCtrl.text = (med['reorder_level'] ?? '0').toString();
      _categoryId = med['category_id']?.toString();
      _supplierId = med['supplier_id']?.toString();
      _manufacturerId = med['manufacturer_id']?.toString();
      _packSizeId = med['pack_size_id']?.toString();
      _shelfLocationId = med['shelf_location_id']?.toString();
      _isControlled = med['is_controlled'] == 1;
      _stopSale = med['stop_sale'] == 1;
      _isCostly = med['is_costly'] == 1;
    });
  }

  void _handleSave() async {
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    
    if (_brandNameCtrl.text.isEmpty && _displayNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand Name or Display Name is required'), backgroundColor: Colors.red),
      );
      return;
    }

    final data = {
      'id': _editingId,
      'category_id': _categoryId,
      'supplier_id': _supplierId,
      'manufacturer_id': _manufacturerId,
      'brand_name': _brandNameCtrl.text,
      'strength': _strengthCtrl.text,
      'generic_name': _genericNameCtrl.text,
      'display_name': _displayNameCtrl.text,
      'pack_size_id': _packSizeId,
      'pack_quantity': int.tryParse(_packQtyCtrl.text) ?? 1,
      'shelf_location_id': _shelfLocationId,
      'max_discount_pct': double.tryParse(_maxDiscountCtrl.text) ?? 0,
      'reorder_level': int.tryParse(_reorderLevelCtrl.text) ?? 0,
      'is_controlled': _isControlled ? 1 : 0,
      'stop_sale': _stopSale ? 1 : 0,
      'is_costly': _isCostly ? 1 : 0,
    };

    final success = await prov.saveMedicine(data);
    if (success) {
      final String action = _editingId == null ? 'saved' : 'modified';
      _resetForm();
      if (mounted) {
        // Show the requested popup
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: kTeal, size: 64),
                const SizedBox(height: 16),
                Text('Medicine $action Successfully!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 8),
                const Text('The medicine record has been updated in the directory.', textAlign: TextAlign.center, style: TextStyle(color: kTextMid)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: kWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Great!'),
                  ),
                )
              ],
            ),
          ),
        );
      }
    }
  }

  void _updateDisplayName() {
    // Only update if Brand Name or Strength changes
    // This logic mimics React's buildMedicineNameWithStrength
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    final String brand = _brandNameCtrl.text;
    final String strength = _strengthCtrl.text;
    if (brand.isNotEmpty) {
      // In React, this is done on save, but for "Display Name" field to live update:
      final String newName = prov.buildMedicineNameWithStrength(brand, strength);
      _displayNameCtrl.text = newName;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PharmacyProvider>(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;
    
    return BaseScaffold(
      title: 'Add / Modify Medicines',
      drawerIndex: 17,
      actions: [
        IconButton(
          onPressed: _resetForm,
          icon: const Icon(Icons.add_circle_outline, color: kWhite),
          tooltip: 'New Medicine',
        ),
        if (_editingId != null)
          IconButton(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline, color: kWhite),
            tooltip: 'Delete Medicine',
          ),
        IconButton(
          onPressed: _handleSave,
          icon: const Icon(Icons.save_outlined, color: kWhite),
          tooltip: _editingId != null ? 'Modify Medicine' : 'Save Medicine',
        ),
      ],
      body: prov.isLoading && prov.medicines.isEmpty
          ? const CustomLoader(color: kTeal)
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ─── UPPER PART: COMPACT FORM (NATURAL HEIGHT) ──────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildCompactForm(prov, isMobile),
                  ),
                  
                  // ─── LOWER PART: EXPANDED DIRECTORY (BOUNDED HEIGHT) ─────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Larger bottom padding for bottom nav space
                    child: _buildDirectorySheet(prov),
                  ),
                ],
              ),
            ),
    );
  }



  void _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    if (confirm == true && mounted) {
      final prov = Provider.of<PharmacyProvider>(context, listen: false);
      if (await prov.deleteMedicine(_editingId!)) {
        _resetForm();
      }
    }
  }

  Widget _buildCompactForm(PharmacyProvider prov, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_outlined, size: 20, color: kTeal),
              const SizedBox(width: 8),
              const Text('Medicine Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark)),
              const Spacer(),
              if (_editingId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                  child: const Text('EDITING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: kTeal)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown('Category', prov.categories, _categoryId, (v) => setState(() => _categoryId = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Supplier', prov.suppliers, _supplierId, (v) => setState(() => _supplierId = v))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField('Brand Name', _brandNameCtrl, icon: Icons.branding_watermark_outlined, onChanged: (_) => _updateDisplayName())),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Strength', _strengthCtrl, icon: Icons.fitness_center, onChanged: (_) => _updateDisplayName())),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildDropdown('Manufacturer', prov.manufacturers, _manufacturerId, (v) => setState(() => _manufacturerId = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Generic Name', _genericNameCtrl, icon: Icons.science_outlined)),
            ],
          ),
          _buildTextField('Display Name', _displayNameCtrl, icon: Icons.text_fields, hint: 'Clean name for prescription'),
          Row(
            children: [
              Expanded(child: _buildDropdown('Pack Size', prov.packSizes, _packSizeId, (v) => setState(() => _packSizeId = v))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Shelf Location', prov.shelfLocations, _shelfLocationId, (v) => setState(() => _shelfLocationId = v))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildTextField('Pack Qty', _packQtyCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Max Discount %', _maxDiscountCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Reorder Level', _reorderLevelCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildModernCheckbox('Controlled', _isControlled, (v) => setState(() => _isControlled = v!)),
              _buildModernCheckbox('Stop Sale', _stopSale, (v) => setState(() => _stopSale = v!)),
              _buildModernCheckbox('Costly', _isCostly, (v) => setState(() => _isCostly = v!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCheckbox(String label, bool value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? kTeal.withOpacity(0.3) : kBorder.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: kTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: value ? kTeal : kTextDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectorySheet(PharmacyProvider prov) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildSearchHeader(prov),
            SizedBox(
              height: 500, // Fixed height for total directory area
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: isMobile ? 650 : size.width - 32,
                    child: Column(
                      children: [
                        _buildTableHeader(),
                        const Divider(height: 1, color: kBorder),
                        Expanded(child: _buildMedicineList(prov)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(PharmacyProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Medicines Directory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextDark)),
                Text('List of all pharmacy medicines', style: TextStyle(fontSize: 9, color: kTextMid)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 1,
            child: SizedBox(
              height: 32,
              child: TextField(
                onChanged: (v) => prov.setMedicineSearchTerm(v),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 14),
                  filled: true,
                  fillColor: kBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kTeal)),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: kHeaderBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text('SR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(flex: 1, child: Text('CATEGORY / BRAND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(flex: 2, child: Text('MEDICINE (DISPLAY NAME)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(flex: 1, child: Text('POTENCY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('UNIT', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTeal))),
        ],
      ),
    );
  }

  Widget _buildMedicineList(PharmacyProvider prov) {
    if (prov.isLoading) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CustomLoader(color: kBlue)));
    if (prov.filteredMedicines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(Icons.inventory_2_outlined, size: 48, color: kBorder),
            SizedBox(height: 12),
            Text('No medicines found', style: TextStyle(color: kTextMid, fontSize: 13)),
          ],
        ),
      );
    }

    return Scrollbar(
      child: ListView.separated(
        itemCount: prov.filteredMedicines.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: kBg),
        itemBuilder: (context, index) {
          final med = prov.filteredMedicines[index];
          return InkWell(
            onTap: () => _fillForm(med),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: index % 2 == 0 ? kWhite : kBg.withOpacity(0.5)),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: kTextMid))),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med['category_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextDark), overflow: TextOverflow.ellipsis),
                        Text(med['brand_name'] ?? '-', style: const TextStyle(fontSize: 8, color: kTextMid), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(med['display_name'] ?? med['medicine_name'] ?? 'Unknown', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextDark), overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(flex: 1, child: Text(med['strength'] ?? 'Default', style: const TextStyle(fontSize: 11, color: kTextDark))),
                  Expanded(flex: 1, child: Text('Rs.${med['last_sale_rate'] ?? '0'}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextDark))),
                  Expanded(flex: 1, child: Text(med['pack_size_name'] ?? '1x1', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTeal))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, IconData? icon, String? hint, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                prefixIcon: icon != null ? Icon(icon, size: 16, color: kTextMid.withOpacity(0.5)) : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kTeal, width: 1.2)),
                filled: true,
                fillColor: kWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: DropdownButtonFormField<String>(
              initialValue: (value != null && items.any((i) => i['id'].toString() == value)) ? value : null,
              onChanged: onChanged,
              icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 16, color: Color(0xFF64748B)),
              isExpanded: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kTeal, width: 1.2)),
                filled: true,
                fillColor: kWhite,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None', style: TextStyle(fontSize: 12, color: Colors.grey))),
                ...items.map((i) => DropdownMenuItem(
                  value: i['id'].toString(),
                  child: Text(i['name'] ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
