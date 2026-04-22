import 'package:flutter/material.dart';

class ShiftDashboardInfo {
  final int shiftId;
  final String shiftType;
  final String shiftDate;

  ShiftDashboardInfo({
    required this.shiftId,
    required this.shiftType,
    required this.shiftDate,
  });

  factory ShiftDashboardInfo.fromJson(Map<String, dynamic> json) {
    return ShiftDashboardInfo(
      shiftId: json['shift_id'] ?? 0,
      shiftType: json['shift_type'] ?? 'Unknown',
      shiftDate: json['shift_date'] ?? '',
    );
  }
}

class DashboardStat {
  final String title;
  final double value;
  final double? prevValue;
  final String? subtitle;
  final bool isCurrency;

  DashboardStat({
    required this.title,
    required this.value,
    this.prevValue,
    this.subtitle,
    this.isCurrency = false,
  });

  String get trend {
    if (prevValue == null || prevValue == 0) return '0%';
    final change = ((value - prevValue!) / prevValue!) * 100;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  bool get trendUp => (value - (prevValue ?? 0)) >= 0;
}

class ChartDataPoint {
  final String x;
  final double y;
  final String? category;

  ChartDataPoint(this.x, this.y, {this.category});
}

class ExpenseBreakdownItem {
  final String name;
  final double value;
  final Color color;

  ExpenseBreakdownItem({
    required this.name,
    required this.value,
    required this.color,
  });
}

class CalendarAppointmentData {
  final String doctorName;
  final List<dynamic> appointments;

  CalendarAppointmentData({
    required this.doctorName,
    required this.appointments,
  });
}
