import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/consultation_model/doctor_model.dart';
import '../../../models/consultation_model/appointment_model.dart';
import '../../../providers/mobile_auth_provider.dart';
import '../../../../custum widgets/custom_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../global/global_api.dart';

class PatientAppointmentDialog extends StatefulWidget {
  final DoctorInfo doctor;

  const PatientAppointmentDialog({
    super.key,
    required this.doctor,
  });

  @override
  State<PatientAppointmentDialog> createState() => _PatientAppointmentDialogState();
}

class _PatientAppointmentDialogState extends State<PatientAppointmentDialog> {
  static const Color primary = Color(0xFF00B5AD);

  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  String _selectedType = 'In-Person';
  bool _isFirstVisit = false; // Usually false for portal users as they have MR

  @override
  void initState() {
    super.initState();
    // Default to today if doctor is available, otherwise find next available day
    _findNextAvailableDate();
    
    // Fetch initial slots
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSlots();
    });
  }

  void _loadSlots() {
    final year = _selectedDate.year;
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final dateStr = '$year-$month-$day';
    
    context.read<MobileAuthProvider>().fetchPortalSlots(
      int.tryParse(widget.doctor.id) ?? 0, 
      dateStr
    );
  }

  void _findNextAvailableDate() {
    final now = DateTime.now();
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dayName = dayNames[date.weekday % 7];
        if (widget.doctor.availableDays.contains(dayName)) {
            _selectedDate = date;
            break;
        }
    }
  }

  Future<void> _pickDate() async {
    DateTime tempMonth = DateTime(_selectedDate.year, _selectedDate.month);
    DateTime tempDate = _selectedDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, sd) {
        final firstDay = DateTime(tempMonth.year, tempMonth.month, 1);
        final daysInMonth = DateTime(tempMonth.year, tempMonth.month + 1, 0).day;
        final startWeekday = firstDay.weekday % 7;
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final today = DateTime.now();

        final cells = <Widget>[];
        for (int i = 0; i < startWeekday; i++) cells.add(const SizedBox());
        for (int d = 1; d <= daysInMonth; d++) {
          final date = DateTime(tempMonth.year, tempMonth.month, d);
          final dayName = dayNames[date.weekday % 7];
          final isAvail = widget.doctor.availableDays.contains(dayName);
          final isPast =
              date.isBefore(DateTime(today.year, today.month, today.day));
          final isSel = date.year == tempDate.year &&
              date.month == tempDate.month &&
              date.day == tempDate.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          cells.add(GestureDetector(
            onTap: isAvail && !isPast ? () => sd(() => tempDate = date) : null,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSel
                    ? primary
                    : isToday
                        ? primary.withOpacity(0.15)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Text('$d',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSel
                            ? Colors.white
                            : isPast || !isAvail
                                ? Colors.grey.shade300
                                : Colors.black87,
                      ))),
            ),
          ));
        }
        
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.calendar_month_rounded, color: primary, size: 22),
                const SizedBox(width: 8),
                const Text('Select Date',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded, color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => sd(() => tempMonth =
                      DateTime(tempMonth.year, tempMonth.month - 1)),
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chevron_left_rounded, color: primary)),
                ),
                Text('${months[tempMonth.month - 1]} ${tempMonth.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(
                  onTap: () => sd(() => tempMonth =
                      DateTime(tempMonth.year, tempMonth.month + 1)),
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chevron_right_rounded, color: primary)),
                ),
              ]),
              const SizedBox(height: 10),
              Row(
                  children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map((d) => Expanded(
                              child: Center(
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade500)))))
                      .toList()),
              const SizedBox(height: 4),
              GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: cells),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempDate),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Confirm Date',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        );
      }),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      _loadSlots();
    }
  }

  Future<void> _submit() async {
    final authProv = context.read<MobileAuthProvider>();
    final user = authProv.currentUser;
    if (user == null) {
      _snack('Session expired. Please login again.', err: true);
      return;
    }

    if (_selectedSlot == null) {
      _snack('Please select a time slot', err: true);
      return;
    }

    final year = _selectedDate.year;
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final dateStr = '$year-$month-$day';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomLoader(size: 80)),
    );

    final result = await authProv.bookPatientPortalAppointment(
      int.tryParse(widget.doctor.id) ?? 0,
      dateStr,
      _selectedSlot!,
    );

    if (mounted) Navigator.pop(context); // Close loader

    if (result['success'] == true) {
      if (mounted) Navigator.pop(context); // Close dialog
      _snack('Appointment booked successfully! A confirmation notification will be sent.', err: false);
    } else {
      _snack(result['message'] ?? 'Booking failed', err: true);
    }
  }

  void _snack(String msg, {required bool err}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: err ? Colors.red.shade400 : primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _dateLabel(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const wdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isPastTime(String slotTime) {
    // Only check if selected date is today
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final selectedStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (todayStr != selectedStr) return false;

    try {
      final parts = slotTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final nowMinutes = now.hour * 60 + now.minute;
      final slotMinutes = hour * 60 + minute;

      return slotMinutes <= nowMinutes;
    } catch (_) {
      return false;
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 0, 0, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  String _initials(String name) {
    final parts = name.replaceAll('Dr. ', '').split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }

  Widget _buildFeeInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
      ],
    );
  }

  Widget _buildPlaceholder(double sw) {
    return Container(
      color: primary.withOpacity(0.05),
      child: Center(
        child: Text(
          _initials(widget.doctor.name),
          style: TextStyle(
            color: primary.withOpacity(0.4),
            fontSize: sw * 0.08,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    
    final authProv = Provider.of<MobileAuthProvider>(context);
    final allSlots = authProv.portalSlots;
    final message = authProv.portalSlotsMessage;
    final loading = authProv.isLoadingSlots;

    final openCount = allSlots.where((s) => s['status'] == 'available').length;
    final bookedCount = allSlots.where((s) => s['status'] != 'available').length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
          horizontal: sw >= 720 ? sw * 0.1 : sw * 0.04,
          vertical: sh * 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            padding: EdgeInsets.all(sw * 0.04),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF00B5AD), Color(0xFF00897B)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.event_available_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Book Appointment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Confirm your visit with ${widget.doctor.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Date Picker
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primary.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.calendar_today_rounded, color: primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('APPOINTMENT DATE', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(_dateLabel(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ]),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Doctor Info Card (Matching admin dialog)
                Container(
                  padding: EdgeInsets.all(sw * 0.035),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Doctor Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctor.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.doctor.specialty.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: primary.withOpacity(0.8),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.doctor.department,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildFeeInfo('Cons.', 'Rs. ${widget.doctor.consultationFee}', Icons.payments_outlined),
                                const SizedBox(width: 16),
                                _buildFeeInfo('F.Up', 'Rs. ${widget.doctor.followUpCharges}', Icons.history_rounded),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: widget.doctor.availableDays.map((day) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right: Image (Matching admin dialog exactly)
                      Hero(
                        tag: 'doctor_img_${widget.doctor.id}',
                        child: Container(
                          width: sw * 0.3,
                          height: sw * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(sw * 0.03),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(sw * 0.03),
                            child: Builder(
                              builder: (context) {
                                final url = GlobalApi.getImageUrl(widget.doctor.imageAsset);
                                if (url != null && url.isNotEmpty) {
                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, _) => _buildPlaceholder(sw),
                                    errorWidget: (context, _, __) => _buildPlaceholder(sw),
                                  );
                                }
                                return _buildPlaceholder(sw);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Slots Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AVAILABLE TIME SLOTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    if (!loading && allSlots.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text('$openCount Open', style: const TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text('$bookedCount Taken', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CustomLoader(size: 40)))
                else if (allSlots.isEmpty)
                   Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(message.isNotEmpty ? message : 'No slots available for this date.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final slotWidth = (constraints.maxWidth - 24) / 3; // 24 = spacing * 2
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: allSlots.map((slotData) {
                          final slotTime = slotData['time'] ?? '';
                          final isAvailable = slotData['status'] == 'available';
                          final isBooked = !isAvailable;
                          final isPast = _isPastTime(slotTime);
                          final isSelected = _selectedSlot == slotTime;
                          
                          final bool isDisabled = isBooked || isPast;

                          return GestureDetector(
                            onTap: isDisabled ? null : () => setState(() => _selectedSlot = slotTime),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: slotWidth,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? primary 
                                    : (isPast ? Colors.teal.shade50 : (isBooked ? Colors.grey.shade100 : Colors.white)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isSelected 
                                        ? primary 
                                        : (isPast ? Colors.teal.shade100 : (isBooked ? Colors.grey.shade200 : Colors.grey.shade300)),
                                    width: isSelected ? 1.5 : 1),
                                boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(slotTime),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? Colors.white 
                                            : (isPast ? Colors.teal.shade300 : (isBooked ? Colors.grey.shade300 : const Color(0xFF334155)))),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPast ? 'PAST' : (isBooked ? 'TAKEN' : 'OPEN'),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isSelected 
                                          ? Colors.white.withOpacity(0.8) 
                                          : (isPast ? Colors.teal.shade200 : (isBooked ? Colors.grey.shade300 : Colors.teal.shade400)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                
                const SizedBox(height: 24),
                // Footer Buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
