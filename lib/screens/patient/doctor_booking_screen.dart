import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../global/global_api.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../custum widgets/custom_loader.dart';

class DoctorBookingScreen extends StatefulWidget {
  final dynamic doctor;
  final String? initialSlot;
  const DoctorBookingScreen({super.key, required this.doctor, this.initialSlot});

  @override
  State<DoctorBookingScreen> createState() => _DoctorBookingScreenState();
}

class _DoctorBookingScreenState extends State<DoctorBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  static const _teal = Color(0xFF00B5AD);

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSlot;
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoadingSlots = true);
    final authProvider = context.read<MobileAuthProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await authProvider.fetchSlots(
        widget.doctor['doctor_srl_no'].toString(), dateStr);

    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          // Keep all slots, don't filter just for available
          _availableSlots = result['data']['slots'] ?? [];
        } else {
          _availableSlots = [];
        }
        
        // Reset selection if the slot is no longer available or has passed
        if (_selectedSlot != null) {
          final slotData = _availableSlots.firstWhere(
            (s) => s['time'] == _selectedSlot, 
            orElse: () => null
          );
          if (slotData == null || slotData['status'] != 'available' || _isPastTime(_selectedSlot!)) {
            _selectedSlot = null;
          }
        }
        _isLoadingSlots = false;
      });
    }
  }

  bool _isPastTime(String slotTime) {
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

  Future<void> _handleBooking() async {
    if (_selectedSlot == null) return;
    setState(() => _isBooking = true);
    final authProvider = context.read<MobileAuthProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final result = await authProvider.book(
      widget.doctor['doctor_srl_no'].toString(),
      dateStr,
      _selectedSlot!,
    );

    if (mounted) {
      setState(() => _isBooking = false);
      if (result['success'] == true) {
        final appId =
            result['data']?['appointment_id'] ?? result['appointment_id'] ?? '-';
        _showSuccessDialog(appId.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Booking failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String appointmentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 44),
              ),
              const SizedBox(height: 16),
              const Text('Appointment Booked!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('ID: #$appointmentId',
                    style: const TextStyle(
                        color: _teal, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              Text(
                'A confirmation has been sent to your WhatsApp.',
                textAlign: TextAlign.center,
                style:
                TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Home',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final topPadding = MediaQuery.of(context).padding.top;
    final slotColumns = size.width < 360 ? 2 : (size.width >= 600 ? 4 : 3);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          // ── Custom AppBar ─────────────────────────────────────────────────
          _buildAppBar(topPadding),

          // ── Scrollable Body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Doctor Card
                  _buildDoctorCard(isSmall),
                  const SizedBox(height: 16),

                  // Date Picker Card
                  _buildSectionLabel('Select Date'),
                  const SizedBox(height: 10),
                  _buildDatePicker(),
                  const SizedBox(height: 20),

                  // Slots
                  _buildSectionLabel('Available Slots'),
                  const SizedBox(height: 10),
                  _buildSlotGrid(slotColumns, isSmall),

                  const SizedBox(height: 32),

                  // Confirm Button
                  _buildConfirmButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar(double topPadding) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C9C0), Color(0xFF00B5AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3300B5AD),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: topPadding + 8,
        bottom: 18,
        left: 8,
        right: 16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            splashRadius: 24,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Book Appointment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Doctor Card ───────────────────────────────────────────────────────────
  Widget _buildDoctorCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmall ? 58 : 66,
            height: isSmall ? 58 : 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _teal.withOpacity(0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Builder(
                builder: (context) {
                  final url = GlobalApi.getImageUrl(widget.doctor['image_url']);
                  if (url != null) {
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => _avatarFallback(isSmall),
                      errorWidget: (context, _, __) => _avatarFallback(isSmall),
                    );
                  }
                  return _avatarFallback(isSmall);
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor['doctor_name'] ?? 'Unknown Doctor',
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2340),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.doctor['doctor_specialization'] ?? 'Specialist',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isSmall ? 12 : 13),
                ),
                const SizedBox(height: 4),
                if ((widget.doctor['doctor_department'] ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.doctor['doctor_department'],
                      style: const TextStyle(
                          color: _teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(bool isSmall) => Icon(Icons.person_rounded,
      size: isSmall ? 28 : 32, color: _teal);

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A2340),
        letterSpacing: 0.2,
      ),
    );
  }

  // ── Date Picker ───────────────────────────────────────────────────────────
  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: _teal),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
          _fetchSlots();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340)),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ── Slot Grid ─────────────────────────────────────────────────────────────
  Widget _buildSlotGrid(int columns, bool isSmall) {
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: CustomLoader(size: 30, color: _teal)),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded,
                size: 38, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('No slots available for this date',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isSmall ? 2.0 : 2.4, // Adjusted for two lines
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final time = slot['time'] ?? '';
        final isAvailable = slot['status'] == 'available';
        final isPast = _isPastTime(time);
        final isSelected = _selectedSlot == time;
        final isDisabled = !isAvailable || isPast;

        return GestureDetector(
          onTap: isDisabled ? null : () => setState(() => _selectedSlot = time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected 
                  ? _teal 
                  : (isPast ? const Color(0xFFF1F5F9) : (isAvailable ? Colors.white : const Color(0xFFF8FAFC))),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? _teal 
                    : (isPast ? const Color(0xFFE2E8F0) : (isAvailable ? Colors.grey.shade200 : const Color(0xFFEDF2F7))),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                    color: _teal.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : (isPast ? Colors.teal.shade300 : (isAvailable ? const Color(0xFF1A2340) : Colors.grey.shade400)),
                    fontWeight: FontWeight.w800,
                    fontSize: isSmall ? 11 : 13,
                  ),
                ),
                Text(
                  isPast ? 'PAST' : (isAvailable ? 'OPEN' : 'TAKEN'),
                  style: TextStyle(
                    fontSize: isSmall ? 8 : 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isSelected 
                        ? Colors.white.withOpacity(0.8) 
                        : (isPast ? Colors.teal.shade200 : (isAvailable ? Colors.teal.shade400 : Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Confirm Button ────────────────────────────────────────────────────────
  Widget _buildConfirmButton() {
    final isDisabled = _selectedSlot == null || _isBooking;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _handleBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          disabledBackgroundColor: _teal.withOpacity(0.4),
          foregroundColor: Colors.white,
          elevation: isDisabled ? 0 : 4,
          shadowColor: _teal.withOpacity(0.35),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isBooking
            ? const CustomLoader(size: 22, color: Colors.white)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text('Confirm Appointment',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
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
}