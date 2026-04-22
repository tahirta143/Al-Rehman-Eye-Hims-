class ShiftModel {
  final int shiftId;
  final String shiftDate;
  final String shiftType;
  final String shiftStartTime;
  final String? shiftEndTime;
  final String openedBy;
  final String? closedBy;
  final bool isClosed;
  final double cashInHand;

  ShiftModel({
    required this.shiftId,
    required this.shiftDate,
    required this.shiftType,
    required this.shiftStartTime,
    this.shiftEndTime,
    required this.openedBy,
    this.closedBy,
    required this.isClosed,
    required this.cashInHand,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      shiftId: json['shift_id'] ?? 0,
      shiftDate: json['shift_date'] ?? '',
      shiftType: json['shift_type'] ?? '',
      shiftStartTime: json['shift_start_time'] ?? '',
      shiftEndTime: json['shift_end_time'],
      openedBy: json['opened_by'] ?? '',
      closedBy: json['closed_by'],
      isClosed: (json['is_closed'] ?? 0) == 1,
      cashInHand:
      double.tryParse(json['cash_in_hand']?.toString() ?? '0') ?? 0.0,
    );
  }

  // Formatted start date only e.g. "2026-02-23"
  String get startDate => shiftStartTime.contains(' ')
      ? shiftStartTime.split(' ')[0]
      : shiftStartTime;

  // Formatted start time only e.g. "09:22 AM"
  String get startTimeFormatted {
    try {
      final timePart = shiftStartTime.contains(' ')
          ? shiftStartTime.split(' ')[1]
          : shiftStartTime;
      final parts = timePart.split(':');
      int hour = int.parse(parts[0]);
      final min = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$min $ampm';
    } catch (_) {
      return shiftStartTime;
    }
  }

  String get formattedCashInHand {
    final formatted = cashInHand.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
    return 'PKR $formatted';
  }

  // Empty/default model for loading state
  static ShiftModel empty() => ShiftModel(
    shiftId: 0,
    shiftDate: '--',
    shiftType: '--',
    shiftStartTime: '--',
    openedBy: '--',
    isClosed: false,
    cashInHand: 0,
  );
}