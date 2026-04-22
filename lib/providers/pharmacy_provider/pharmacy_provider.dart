import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/pharmacy_api_service.dart';

class PharmacyProvider extends ChangeNotifier {
  final PharmacyApiService _apiService = PharmacyApiService();

  // --- Loading States ---
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearchingPatient = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSearchingPatient => _isSearchingPatient;
  String? get errorMessage => _errorMessage;

  // --- Lookups (Bootstrap) ---
  List<dynamic> _categories = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _manufacturers = [];
  List<dynamic> _packSizes = [];
  List<dynamic> _shelfLocations = [];
  String _nextPurchaseCode = '';
  String _nextReceiptNo = '';
  List<dynamic> _heldInvoices = [];
  List<dynamic> _recentInvoices = [];

  List<dynamic> get categories => _categories;
  List<dynamic> get suppliers => _suppliers;
  List<dynamic> get manufacturers => _manufacturers;
  List<dynamic> get packSizes => _packSizes;
  List<dynamic> get shelfLocations => _shelfLocations;
  String get nextPurchaseCode => _nextPurchaseCode;
  String get nextReceiptNo => _nextReceiptNo;
  List<dynamic> get heldInvoices => _heldInvoices;
  List<dynamic> get recentInvoices => _recentInvoices;

  // --- Medicines Screen State ---
  List<dynamic> _medicines = [];
  List<dynamic> _filteredMedicines = [];
  String _medicineSearchTerm = '';

  List<dynamic> get medicines => _medicines;
  List<dynamic> get filteredMedicines => _filteredMedicines;
  String get medicineSearchTerm => _medicineSearchTerm;

  // --- Opening Balances State ---
  List<dynamic> _openingBalanceRows = [];
  Map<String, dynamic> _openingBalanceFilters = {
    'categoryId': 'all',
    'supplierId': 'all',
    'manufacturerId': 'all',
    'shelfLocationId': 'all',
    'search': ''
  };
  DateTime _openingDate = DateTime.now();

  List<dynamic> get openingBalanceRows => _openingBalanceRows;
  Map<String, dynamic> get openingBalanceFilters => _openingBalanceFilters;
  DateTime get openingDate => _openingDate;

  // --- Purchase Posting State ---
  Map<String, dynamic> _purchaseHeader = {
    'purchase_code': '',
    'purchase_date': DateTime.now(),
    'supplier_id': null,
    'invoice_no': ''
  };
  List<dynamic> _purchaseItems = [];
  Map<String, dynamic> _purchaseSummary = {
    'total_amount': 0.0,
    'discount_amount': 0.0,
    'payable_amount': 0.0
  };

  Map<String, dynamic> get purchaseHeader => _purchaseHeader;
  List<dynamic> get purchaseItems => _purchaseItems;
  Map<String, dynamic> get purchaseSummary => _purchaseSummary;

  // --- Sales Invoice State ---
  Map<String, dynamic> _salesHeader = {
    'id': null,
    'receipt_no': '',
    'medical_no': '',
    'customer_name': 'WALKING CUSTOMER',
    'opd_no': '',
    'invoice_date': DateTime.now(),
    'card_sale': false
  };
  List<dynamic> _salesItems = [];
  Map<String, dynamic> _salesSummary = {
    'total_price': 0.0,
    'discount_percent': 0.0,
    'discount_amount': 0.0,
    'payable': 0.0,
    'amount_given': 0.0,
    'return_amount': 0.0
  };

  Map<String, dynamic> get salesHeader => _salesHeader;
  List<dynamic> get salesItems => _salesItems;
  Map<String, dynamic> get salesSummary => _salesSummary;

  // Track which discount field was last edited to sync values
  String? _discountSource; 
  Timer? _clockTimer;

  // --- Pharmacy Provider State ---
  bool _isLoadingPrescribedPatients = false;
  bool _isApplyingPrescription = false;
  List<dynamic> _prescribedPatients = [];

  bool get isLoadingPrescribedPatients => _isLoadingPrescribedPatients;
  bool get isApplyingPrescription => _isApplyingPrescription;
  List<dynamic> get prescribedPatients => _prescribedPatients;

  // --- Initialization ---

  Future<void> initBootstrap() async {
    _isLoading = true;
    notifyListeners();
    final res = await _apiService.getPharmacyBootstrap();
    if (res['success'] == true) {
      final data = res['data'];
      _categories = data['categories'] ?? [];
      _suppliers = data['suppliers'] ?? [];
      _manufacturers = data['manufacturers'] ?? [];
      _packSizes = data['packSizes'] ?? [];
      _shelfLocations = data['shelfLocations'] ?? [];
      _nextPurchaseCode = data['nextPurchaseCode']?.toString() ?? '';
      _nextReceiptNo = data['nextReceiptNo']?.toString() ?? '';
      _heldInvoices = data['heldInvoices'] ?? [];
      _recentInvoices = data['recentInvoices'] ?? [];
      
      _purchaseHeader['purchase_code'] = _nextPurchaseCode;
      _salesHeader['receipt_no'] = _nextReceiptNo;

      // Also load prescribed patients on bootstrap if in Sales Invoice flow
      loadPrescribedPatients();
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- Prescribed Patients ---

  Future<void> loadPrescribedPatients() async {
    _isLoadingPrescribedPatients = true;
    notifyListeners();
    final res = await _apiService.getPrescribedPatients();
    if (res['success'] == true) {
      _prescribedPatients = res['data'] ?? [];
    }
    _isLoadingPrescribedPatients = false;
    notifyListeners();
  }

  void startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_salesHeader['id'] == null) {
        _salesHeader['invoice_date'] = DateTime.now();
        notifyListeners();
      }
    });
  }

  void stopClock() {
    _clockTimer?.cancel();
  }


  Future<void> handleUsePrescribedPatient(int prescriptionId) async {
    _isApplyingPrescription = true;
    notifyListeners();
    try {
      final res = await _apiService.getPrescribedPatientById(prescriptionId);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        
        // Update header
        _salesHeader['medical_no'] = data['mr_number'] ?? '';
        _salesHeader['opd_no'] = data['opd_no'] ?? '';
        _salesHeader['customer_name'] = data['patient_name'] ?? 'WALKING CUSTOMER';

        // Map medicines to sales items
        final List<dynamic> meds = data['medicines'] ?? [];
        _salesItems = meds.map((m) {
          final double stock = double.tryParse(m['loose_stock']?.toString() ?? '0') ?? 0;
          
          // Calculate qty based on doses or explicit qty
          // doses_per_day = morning + afternoon + evening + night
          final double doses = (double.tryParse(m['morning']?.toString() ?? '0') ?? 0) +
                              (double.tryParse(m['afternoon']?.toString() ?? '0') ?? 0) +
                              (double.tryParse(m['evening']?.toString() ?? '0') ?? 0) +
                              (double.tryParse(m['night']?.toString() ?? '0') ?? 0);
          final double days = double.tryParse(m['for_days']?.toString() ?? '0') ?? 0;
          double qty = (doses > 0 && days > 0) ? (doses * days) : 1;
          
          // If the API provided an explicit qty, use that
          if (m['qty'] != null && (double.tryParse(m['qty'].toString()) ?? 0) > 0) {
            qty = double.parse(m['qty'].toString());
          }

          final double price = double.tryParse((m['sale_price'] ?? m['purchase_price'] ?? 0).toString()) ?? 0;
          final double total = price * qty;

          return {
            'medicine_id': m['medicine_id'],
            'item_name': m['medicine_name'] ?? '',
            'price': price.toStringAsFixed(2),
            'qty': qty.toString(),
            'total': total.toStringAsFixed(2),
            'in_stock_before': stock,
            'require_purchase': m['medicine_id'] != null && stock < qty
          };
        }).toList();

        _calculateSalesTotals();
      }
    } catch (e) {
      debugPrint('Error applying prescription: $e');
    } finally {
      _isApplyingPrescription = false;
      notifyListeners();
    }
  }

  Future<bool> deletePrescribedPatient(int prescriptionId) async {
    final res = await _apiService.deletePrescribedPatient(prescriptionId);
    if (res['success'] == true) {
      _prescribedPatients.removeWhere((p) => p['prescription_id'] == prescriptionId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Medicines CRUD ---

  Future<void> loadMedicines() async {
    _isLoading = true;
    notifyListeners();
    final res = await _apiService.getAllMedicines();
    if (res['success'] == true) {
      _medicines = res['data'] ?? [];
      _applyMedicineFilter();
    }
    _isLoading = false;
    notifyListeners();
  }

  void setMedicineSearchTerm(String term) {
    _medicineSearchTerm = term;
    _applyMedicineFilter();
    notifyListeners();
  }

  void _applyMedicineFilter() {
    if (_medicineSearchTerm.isEmpty) {
      _filteredMedicines = List.from(_medicines);
    } else {
      final lower = _medicineSearchTerm.toLowerCase();
      _filteredMedicines = _medicines.where((m) {
        final name = (m['medicine_name'] ?? '').toString().toLowerCase();
        final generic = (m['generic_name'] ?? '').toString().toLowerCase();
        final brand = (m['brand_name'] ?? '').toString().toLowerCase();
        return name.contains(lower) || generic.contains(lower) || brand.contains(lower);
      }).toList();
    }
  }

  String buildMedicineNameWithStrength(String name, String strength) {
    final cleanName = name.trim();
    final cleanStrength = strength.trim();
    if (cleanStrength.isEmpty) return cleanName;
    
    // Exact match for React's buildMedicineNameWithStrength logic:
    // 1. Normalize name (remove trailing strength if present)
    // 2. Append strength at the end
    
    // Case-insensitive regex to find trailing strength with possible space prefix
    final String escapedStrength = RegExp.escape(cleanStrength);
    final RegExp suffixRegex = RegExp('\\s+$escapedStrength\$', caseSensitive: false);
    final String base = cleanName.replaceAll(suffixRegex, '').trim();
    
    return '$base $cleanStrength'.trim();
  }

  Future<bool> saveMedicine(Map<String, dynamic> data) async {
    _isSaving = true;
    notifyListeners();
    
    // Sync React's name construction logic
    final String primaryName = (data['display_name'] ?? data['brand_name'] ?? data['medicine_name'] ?? '').toString();
    final String strengthText = (data['strength'] ?? '').toString();
    final String constructedName = buildMedicineNameWithStrength(primaryName, strengthText);

    final Map<String, dynamic> payload = {
      ...data,
      'medicine_name': constructedName,
      'display_name': constructedName
    };

    final bool isUpdate = payload['id'] != null;
    final res = isUpdate 
      ? await _apiService.updateMedicine(payload['id'], payload)
      : await _apiService.createMedicine(payload);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      await loadMedicines();
      return true;
    }
    return false;
  }

  Future<bool> deleteMedicine(int id) async {
    _isSaving = true;
    notifyListeners();
    final res = await _apiService.deleteMedicine(id);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      await loadMedicines();
      return true;
    }
    return false;
  }

  // --- Opening Balances ---

  void setOpeningBalanceFilter(String key, dynamic value) {
    _openingBalanceFilters[key] = value;
    notifyListeners();
  }

  void setOpeningDate(DateTime date) {
    _openingDate = date;
    notifyListeners();
  }

  Future<void> loadOpeningBalances() async {
    _isLoading = true;
    notifyListeners();
    
    // Only send non-'all' filters to the API
    final Map<String, dynamic> params = {};
    _openingBalanceFilters.forEach((key, value) {
      if (value != null && value != 'all' && value != '') {
        params[key] = value;
      }
    });

    final res = await _apiService.getOpeningBalanceRows(params);
    if (res['success'] == true) {
      _openingBalanceRows = (res['data'] ?? []).map((r) {
        return {
          ...r,
          'loose_purchase': r['loose_purchase'] ?? 0,
          'loose_sale': r['loose_sale'] ?? 0,
          'loose_stock': r['loose_stock'] ?? 0
        };
      }).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  void updateOpeningBalanceRow(int index, String field, dynamic value) {
    _openingBalanceRows[index][field] = value;
    notifyListeners();
  }

  Future<bool> saveOpeningBalances() async {
    final itemsToSave = _openingBalanceRows.where((r) => (double.tryParse(r['loose_stock']?.toString() ?? '0') ?? 0) > 0).toList();
    if (itemsToSave.isEmpty) return false;

    _isSaving = true;
    notifyListeners();
    final payload = {
      'openingDate': _openingDate.toIso8601String().split('T')[0],
      'items': itemsToSave.map((r) => {
        'medicine_id': r['id'],
        'supplier_id': r['supplier_id'],
        'manufacturer_id': r['manufacturer_id'],
        'shelf_location_id': r['shelf_location_id'],
        'unit': r['unit'],
        'pack': r['pack'],
        'loose_purchase': double.tryParse(r['loose_purchase']?.toString() ?? '0') ?? 0,
        'loose_sale': double.tryParse(r['loose_sale']?.toString() ?? '0') ?? 0,
        'loose_stock': double.tryParse(r['loose_stock']?.toString() ?? '0') ?? 0
      }).toList()
    };
    final res = await _apiService.saveOpeningBalances(payload);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      await loadOpeningBalances();
      return true;
    }
    return false;
  }

  // --- Purchase Posting ---

  void updatePurchaseHeader(String key, dynamic value) {
    _purchaseHeader[key] = value;
    notifyListeners();
  }

  void addPurchaseItem(Map<String, dynamic> item) {
    _purchaseItems.add(item);
    _calculatePurchaseTotals();
    notifyListeners();
  }

  void removePurchaseItem(int index) {
    _purchaseItems.removeAt(index);
    _calculatePurchaseTotals();
    notifyListeners();
  }

  void updatePurchaseDiscount(double amount) {
    _purchaseSummary['discount_amount'] = amount;
    _calculatePurchaseTotals();
    notifyListeners();
  }

  void _calculatePurchaseTotals() {
    double total = 0;
    for (var item in _purchaseItems) {
      total += double.tryParse(item['total']?.toString() ?? '0') ?? 0;
    }
    _purchaseSummary['total_amount'] = total;
    _purchaseSummary['payable_amount'] = total - (_purchaseSummary['discount_amount'] ?? 0);
  }

  Future<Map<String, dynamic>> savePurchase() async {
    if (_purchaseHeader['supplier_id'] == null || _purchaseItems.isEmpty) {
      return {'success': false, 'message': 'Supplier and items are required'};
    }
    _isSaving = true;
    notifyListeners();
    final payload = {
      ..._purchaseHeader,
      'purchase_date': (_purchaseHeader['purchase_date'] as DateTime).toIso8601String().split('T')[0],
      'total_amount': _purchaseSummary['total_amount'],
      'discount_amount': _purchaseSummary['discount_amount'],
      'payable_amount': _purchaseSummary['payable_amount'],
      'items': _purchaseItems
    };
    final res = await _apiService.createPurchase(payload);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      _resetPurchase();
      await initBootstrap();
    }
    return res;
  }

  void _resetPurchase() {
    _purchaseHeader = {
      'purchase_code': _nextPurchaseCode,
      'purchase_date': DateTime.now(),
      'supplier_id': null,
      'invoice_no': ''
    };
    _purchaseItems = [];
    _purchaseSummary = {
      'total_amount': 0.0,
      'discount_amount': 0.0,
      'payable_amount': 0.0
    };
    notifyListeners();
  }

  // --- Sales Invoice ---

  void updateSalesHeader(String key, dynamic value) {
    _salesHeader[key] = value;
    notifyListeners();
  }

  void addSalesItem(Map<String, dynamic> item) {
    _salesItems.add(item);
    _calculateSalesTotals();
    notifyListeners();
  }

  void removeSalesItem(int index) {
    _salesItems.removeAt(index);
    _calculateSalesTotals();
    notifyListeners();
  }

  void updateSalesDiscountPercent(double percent) {
    _discountSource = 'percent';
    _salesSummary['discount_percent'] = percent;
    _calculateSalesTotals(source: 'percent');
    notifyListeners();
  }

  void updateSalesDiscountAmount(double amount) {
    _discountSource = 'amount';
    _salesSummary['discount_amount'] = amount;
    _calculateSalesTotals(source: 'amount');
    notifyListeners();
  }

  void updateSalesAmountGiven(double amount) {
    _salesSummary['amount_given'] = amount;
    _calculateSalesTotals();
    notifyListeners();
  }

  void _calculateSalesTotals({String? source}) {
    double total = 0;
    for (var item in _salesItems) {
      total += double.tryParse(item['total']?.toString() ?? '0') ?? 0;
    }
    _salesSummary['total_price'] = total;
    
    double dAmt = double.tryParse(_salesSummary['discount_amount']?.toString() ?? '0') ?? 0.0;
    
    if (source == 'percent' || (source == null && _discountSource == 'percent')) {
      double pct = double.tryParse(_salesSummary['discount_percent']?.toString() ?? '0') ?? 0.0;
      dAmt = total * (pct / 100);
      _salesSummary['discount_amount'] = dAmt;
    } else if (source == 'amount' || (source == null && _discountSource == 'amount')) {
      // Amount already updated, set percent for display
      _salesSummary['discount_percent'] = total > 0 ? (dAmt / total * 100) : 0.0;
    } else {
      // Default fallback
      double pct = double.tryParse(_salesSummary['discount_percent']?.toString() ?? '0') ?? 0.0;
      dAmt = total * (pct / 100);
      _salesSummary['discount_amount'] = dAmt;
    }

    double payable = total - dAmt;
    if (payable < 0) payable = 0;
    _salesSummary['payable'] = payable;

    double given = _salesSummary['amount_given'] ?? 0.0;
    _salesSummary['return_amount'] = (given >= payable) ? (given - payable) : 0.0;
  }

  Future<bool> finalizeSale() async {
    if (_salesItems.isEmpty) return false;
    
    // Validation: Block if stock is insufficient
    final bool hasInsufficientStock = _salesItems.any((i) => (i['require_purchase'] == true));
    if (hasInsufficientStock) {
      _errorMessage = "Cannot finalize: some items require purchase due to low stock.";
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();
    final payload = _getSalesPayload();
    final res = _salesHeader['id'] != null
      ? await _apiService.updateAndFinalizeSale(_salesHeader['id'], payload)
      : await _apiService.createSale(payload);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      _resetSales();
      await initBootstrap();
      return true;
    }
    return false;
  }

  Future<bool> holdSale() async {
    if (_salesItems.isEmpty || _salesHeader['id'] != null) return false;
    _isSaving = true;
    notifyListeners();
    final payload = _getSalesPayload();
    final res = await _apiService.saveHeldSale(payload);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      _resetSales();
      await initBootstrap();
      return true;
    }
    return false;
  }

  Future<void> resumeHeldSale(int id) async {
    _isLoading = true;
    notifyListeners();
    final res = await _apiService.getSaleById(id);
    if (res['success'] == true) {
      final data = res['data'];
      _salesHeader = {
        'id': data['id'],
        'receipt_no': data['receipt_no'],
        'medical_no': data['medical_no'] ?? '',
        'customer_name': data['customer_name'] ?? 'WALKING CUSTOMER',
        'opd_no': data['opd_no'] ?? '',
        'invoice_date': data['invoice_date'] != null ? DateTime.parse(data['invoice_date']) : DateTime.now(),
        'card_sale': data['card_sale'] == 1 || data['card_sale'] == true
      };
      _salesItems = data['items'] ?? [];
      _salesSummary = {
        'total_price': double.tryParse(data['total_amount']?.toString() ?? '0') ?? 0.0,
        'discount_percent': double.tryParse(data['discount_percent']?.toString() ?? '0') ?? 0.0,
        'discount_amount': double.tryParse(data['discount_amount']?.toString() ?? '0') ?? 0.0,
        'payable': double.tryParse(data['payable_amount']?.toString() ?? '0') ?? 0.0,
        'amount_given': double.tryParse(data['amount_given']?.toString() ?? '0') ?? 0.0,
        'return_amount': double.tryParse(data['return_amount']?.toString() ?? '0') ?? 0.0
      };
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteHeldSale(int id) async {
    _isSaving = true;
    notifyListeners();
    final res = await _apiService.deleteHeldSale(id);
    _isSaving = false;
    notifyListeners();
    if (res['success'] == true) {
      if (_salesHeader['id'] == id) _resetSales();
      await initBootstrap();
      return true;
    }
    return false;
  }

  Map<String, dynamic> _getSalesPayload() {
    return {
      ..._salesHeader,
      'invoice_date': (_salesHeader['invoice_date'] as DateTime).toIso8601String().replaceFirst('T', ' ').split('.')[0],
      'discount_percent': _salesSummary['discount_percent'],
      'discount_amount': _salesSummary['discount_amount'],
      'total_amount': _salesSummary['total_price'],
      'payable_amount': _salesSummary['payable'],
      'amount_given': _salesSummary['amount_given'],
      'return_amount': _salesSummary['return_amount'],
      'items': _salesItems
    };
  }

  void _resetSales() {
    _salesHeader = {
      'id': null,
      'receipt_no': _nextReceiptNo,
      'medical_no': '',
      'customer_name': 'WALKING CUSTOMER',
      'opd_no': '',
      'invoice_date': DateTime.now(),
      'card_sale': false
    };
    _salesItems = [];
    _salesSummary = {
      'total_price': 0.0,
      'discount_percent': 0.0,
      'discount_amount': 0.0,
      'payable': 0.0,
      'amount_given': 0.0,
      'return_amount': 0.0
    };
    notifyListeners();
  }

  Future<Map<String, dynamic>> searchMedicines(String query) async {
    return await _apiService.searchPharmacyMedicines(query);
  }

  Future<void> searchPatientByMR(String mr) async {
    if (mr.isEmpty) return;
    _isSearchingPatient = true;
    notifyListeners();
    try {
      final res = await _apiService.getPatientByMR(mr);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final fullName = "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim();
        _salesHeader['customer_name'] = fullName.isNotEmpty ? fullName : 'WALKING CUSTOMER';
        _salesHeader['medical_no'] = mr;
      } else {
        _salesHeader['customer_name'] = 'WALKING CUSTOMER';
      }
    } catch (e) {
      _salesHeader['customer_name'] = 'WALKING CUSTOMER';
    } finally {
      _isSearchingPatient = false;
      notifyListeners();
    }
  }
}
