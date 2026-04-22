class ExpenseModel {
  final int srlNo;
  final String id;
  final String expenseDate;
  final String expenseTime;
  final String expenseShift;
  final String category;
  final double amount;
  final String expenseBy;
  final String description;
  final int shiftId;
  final String shiftDate; // ← add this

  ExpenseModel({
    required this.srlNo,
    required this.id,
    required this.expenseDate,
    required this.expenseTime,
    required this.expenseShift,
    required this.category,
    required this.amount,
    required this.expenseBy,
    required this.description,
    required this.shiftId,
    required this.shiftDate, // ← add this
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      srlNo: json['srl_no'] ?? 0,
      id: json['expense_id'] ?? '',
      expenseDate: json['expense_date'] ?? '',
      expenseTime: json['expense_time'] ?? '',
      expenseShift: json['expense_shift'] ?? '',
      category: json['expense_name'] ?? '',
      amount: double.tryParse(json['expense_amount']?.toString() ?? '0') ?? 0.0,
      expenseBy: json['expense_by'] ?? '',
      description: json['expense_description'] ?? '',
      shiftId: json['shift_id'] ?? 0,
      shiftDate: json['shift_date'] ?? '', // ← add this
    );
  }

  String get formattedAmount {
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return 'PKR $formatted';
  }

  String get formattedTime {
    try {
      final parts = expenseTime.split(':');
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$expenseDate · $hour:$min $ampm';
    } catch (_) {
      return '$expenseDate · $expenseTime';
    }
  }
}