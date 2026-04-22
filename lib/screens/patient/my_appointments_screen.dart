import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../global/global_api.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../custum widgets/custom_loader.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<MobileAuthProvider>();
    final result = await authProvider.fetchMyAppointments();

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _appointments = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancel(String appointmentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      final res = await context
          .read<MobileAuthProvider>()
          .cancelAppointment(appointmentId);
      if (mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Appointment cancelled successfully'),
              backgroundColor: const Color(0xFF00B5AD),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          _fetchAppointments();
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Failed to cancel'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;
    final isMedium = size.width >= 360 && size.width < 600;
    final isLarge = size.width >= 600;

    // Responsive values
    final double cardPadding = isSmall ? 10 : (isMedium ? 12 : 16);
    final double avatarSize = isSmall ? 42 : (isMedium ? 48 : 54);
    final double titleFontSize = isSmall ? 13 : (isMedium ? 14 : 15);
    final double subFontSize = isSmall ? 11 : 12;
    final double listPadding = isSmall ? 10 : (isLarge ? 24 : 14);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          // ── Custom AppBar with rounded bottom corners ──────────────────
          _AppBarWidget(),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                child: CustomLoader(
                    size: 40, color: Color(0xFF00B5AD)))
                : _appointments.isEmpty
                ? _EmptyState()
                : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: listPadding,
                vertical: 16,
              ),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                final status =
                (appt['status'] ?? 'pending').toLowerCase();
                return _AppointmentCard(
                  appt: appt,
                  status: status,
                  cardPadding: cardPadding,
                  avatarSize: avatarSize,
                  titleFontSize: titleFontSize,
                  subFontSize: subFontSize,
                  isSmall: isSmall,
                  getFullImageUrl: (p) => GlobalApi.getImageUrl(p) ?? '',
                  formatTime: _formatTime,
                  onCancel: () =>
                      _handleCancel(appt['id'].toString()),
                );
              },
            ),
          ),
        ],
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

// ────────────────────────────────────────────────────────────────────────────
// Custom AppBar
// ────────────────────────────────────────────────────────────────────────────
class _AppBarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
        top: topPadding ,
        bottom: 18,
        left: 8,
        right: 16,
      ),
      child: Row(
        children: [
          // White back arrow button
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            splashRadius: 24,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'My Appointments',
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
}

// ────────────────────────────────────────────────────────────────────────────
// Appointment Card
// ────────────────────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final String status;
  final double cardPadding;
  final double avatarSize;
  final double titleFontSize;
  final double subFontSize;
  final bool isSmall;
  final String Function(String?) getFullImageUrl;
  final String Function(String) formatTime;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appt,
    required this.status,
    required this.cardPadding,
    required this.avatarSize,
    required this.titleFontSize,
    required this.subFontSize,
    required this.isSmall,
    required this.getFullImageUrl,
    required this.formatTime,
    required this.onCancel,
  });

  Color get _statusColor {
    switch (status) {
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF3498DB);
    }
  }

  Color get _statusBg => _statusColor.withOpacity(0.09);

  IconData get _statusIcon {
    switch (status) {
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Top accent strip ───────────────────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_statusColor.withOpacity(0.7), _statusColor],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Date row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: Color(0xFF00B5AD)),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('EEE, MMM d, yyyy').format(
                                DateTime.parse(appt['appointment_date'])),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00B5AD),
                              fontSize: isSmall ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon,
                                size: 11, color: _statusColor),
                            const SizedBox(width: 3),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Doctor row ───────────────────────────────────────
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF00B5AD).withOpacity(0.1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Builder(
                            builder: (context) {
                              final url = GlobalApi.getImageUrl(appt['image_url']);
                              if (url != null) {
                                return CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, _) => _avatarIcon,
                                  errorWidget: (context, _, __) => _avatarIcon,
                                );
                              }
                              return _avatarIcon;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appt['doctor_name'] ?? 'Doctor',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: titleFontSize,
                                color: const Color(0xFF1A2340),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appt['doctor_specialization'] ?? 'Specialist',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: subFontSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Info chips ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ChipInfo(
                          icon: Icons.access_time_rounded,
                          label: 'Time',
                          value: formatTime(appt['slot_time'] ?? ''),
                          isSmall: isSmall,
                        ),
                        _Divider(),
                        _ChipInfo(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Token',
                          value: appt['token_number']?.toString() ?? '-',
                          isSmall: isSmall,
                        ),
                        _Divider(),
                        _ChipInfo(
                          icon: Icons.payments_outlined,
                          label: 'Fee',
                          value: 'Rs. ${appt['fee'] ?? '-'}',
                          isSmall: isSmall,
                        ),
                      ],
                    ),
                  ),

                  // ── Cancel button ────────────────────────────────────
                  if (status == 'booked' || status == 'pending') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Cancel Appointment',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                              color: Colors.red.shade300, width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.red.withOpacity(0.03),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _avatarIcon => Container(
    color: const Color(0xFF00B5AD).withOpacity(0.08),
    child: const Icon(Icons.person_rounded,
        color: Color(0xFF00B5AD), size: 24),
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Small helpers
// ────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    width: 1,
    color: Colors.grey.shade300,
  );
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSmall;

  const _ChipInfo(
      {required this.icon,
        required this.label,
        required this.value,
        required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: isSmall ? 14 : 15, color: const Color(0xFF00B5AD)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: isSmall ? 9 : 10,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isSmall ? 11 : 12,
                color: const Color(0xFF1A2340))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00B5AD).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined,
                size: 40, color: Color(0xFF00B5AD)),
          ),
          const SizedBox(height: 16),
          const Text('No appointments found',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Book your first appointment today',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}