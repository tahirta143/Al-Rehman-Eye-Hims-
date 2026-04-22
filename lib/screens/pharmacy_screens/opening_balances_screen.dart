import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class OpeningBalancesScreen extends StatefulWidget {
  const OpeningBalancesScreen({super.key});

  @override
  State<OpeningBalancesScreen> createState() => _OpeningBalancesScreenState();
}

class _OpeningBalancesScreenState extends State<OpeningBalancesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<PharmacyProvider>(context, listen: false);
      prov.initBootstrap();
      prov.loadOpeningBalances();
    });
  }

  void _selectDate(BuildContext context) async {
    final prov = Provider.of<PharmacyProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: prov.openingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != prov.openingDate) {
      prov.setOpeningDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PharmacyProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return BaseScaffold(
      title: 'Opening Balances',
      drawerIndex: 18,
      actions: [
        IconButton(
          onPressed: () async {
            final prov = Provider.of<PharmacyProvider>(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            
            final success = await prov.saveOpeningBalances();
            
            if (!mounted) return;
            
            if (success) {
              messenger.showSnackBar(const SnackBar(
                content: Text('Opening balances saved successfully'),
                backgroundColor: kTeal,
              ));
            } else {
              messenger.showSnackBar(const SnackBar(
                content: Text('No changes to save (stock must be > 0)'),
                backgroundColor: Colors.orange,
              ));
            }
          },
          icon: const Icon(Icons.save_as_outlined, color: Colors.white),
          tooltip: 'Save Balances',
        ),
      ],
      body: prov.isLoading && prov.openingBalanceRows.isEmpty
          ? const CustomLoader(color: kTeal)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildFiltersSection(prov, isMobile),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildPremiumTableSheet(prov),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltersSection(PharmacyProvider prov, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown('Category', prov.categories, prov.openingBalanceFilters['categoryId'], 
                (v) => prov.setOpeningBalanceFilter('categoryId', v ?? 'all'), allOption: 'All Categories')),
              const SizedBox(width: 8),
              Expanded(child: _buildDropdown('Shelf Location', prov.shelfLocations, prov.openingBalanceFilters['shelfLocationId'], 
                (v) => prov.setOpeningBalanceFilter('shelfLocationId', v ?? 'all'), allOption: 'All Locations')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDropdown('Supplier', prov.suppliers, prov.openingBalanceFilters['supplierId'], 
                (v) => prov.setOpeningBalanceFilter('supplierId', v ?? 'all'), allOption: 'All Suppliers')),
              const SizedBox(width: 8),
              Expanded(child: _buildDatePickerField(prov)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: (v) => prov.setOpeningBalanceFilter('search', v),
                    decoration: InputDecoration(
                      hintText: 'Search medicine...',
                      hintStyle: const TextStyle(fontSize: 10, color: kTextMid),
                      prefixIcon: const Icon(Icons.search, size: 14, color: kTeal),
                      filled: true,
                      fillColor: kBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: kTeal, width: 1.0)),
                    ),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => prov.loadOpeningBalances(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTeal,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.refresh, size: 14),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDatePickerField(PharmacyProvider prov) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: kTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat('yyyy-MM-dd').format(prov.openingDate),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextDark),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPremiumTableSheet(PharmacyProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildTableHeader(),
            const Divider(height: 1, color: kBg),
            Expanded(
              child: prov.isLoading 
                ? const CustomLoader(color: kTeal)
                : prov.openingBalanceRows.isEmpty
                  ? _buildEmptyState()
                  : _buildBalancesList(prov),
            ),
          ],
        ),
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
          Expanded(flex: 3, child: Text('MEDICINE / BRAND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('UNIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('PACK', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('PUR. RATE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('SALE RATE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTextMid))),
          Expanded(child: Text('STOCK', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: kTeal))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: kBg),
          const SizedBox(height: 16),
          const Text('No medicines found', style: TextStyle(fontSize: 16, color: kTextMid, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBalancesList(PharmacyProvider prov) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Added padding to avoid content hiding behind bottom bar
      itemCount: prov.openingBalanceRows.length,
      itemBuilder: (context, index) {
        final row = prov.openingBalanceRows[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: index % 2 == 0 ? kWhite : kBg.withOpacity(0.5),
            border: const Border(bottom: BorderSide(color: kBg)),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: kTextMid))),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row['medicine_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kTextDark), overflow: TextOverflow.ellipsis),
                    Text(row['supplier_name'] ?? '', style: const TextStyle(fontSize: 8, color: kTextMid), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(child: Text(row['unit'] ?? '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: kTextDark))),
              Expanded(child: Text(row['pack']?.toString() ?? '1', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextDark))),
              _buildEditableCell(index, 'loose_purchase', row['loose_purchase'], prov),
              _buildEditableCell(index, 'loose_sale', row['loose_sale'], prov),
              _buildEditableCell(index, 'loose_stock', row['loose_stock'], prov, isStock: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<dynamic> items, String? value, Function(String?) onChanged, {String allOption = 'All'}) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        value: (value != null && (value == 'all' || items.any((i) => i['id'].toString() == value))) ? value : 'all',
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 16, color: kTextMid),
        menuMaxHeight: 300,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kTeal)),
          filled: true,
          fillColor: kWhite,
          labelText: label.toUpperCase(),
          labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMid),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        style: const TextStyle(fontSize: 11, color: kTextDark, fontWeight: FontWeight.bold),
        items: [
          DropdownMenuItem(value: 'all', child: Text(allOption, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: kTextMid))),
          ...items.map((i) => DropdownMenuItem(
            value: i['id'].toString(),
            child: Text(i['name'] ?? '', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEditableCell(int index, String field, dynamic value, PharmacyProvider prov, {bool isStock = false}) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: SizedBox(
          height: 30,
          child: TextField(
            controller: TextEditingController(text: value?.toString() ?? '0')..selection = TextSelection.collapsed(offset: (value?.toString() ?? '0').length),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            onChanged: (v) {
              prov.updateOpeningBalanceRow(index, field, v);
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isStock ? kTeal.withOpacity(0.3) : kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isStock ? kTeal : kTeal, width: 1.2)),
              filled: true,
              fillColor: isStock ? kTealLight.withOpacity(0.5) : kWhite,
            ),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isStock ? kTeal : kTextDark),
          ),
        ),
      ),
    );
  }
}
