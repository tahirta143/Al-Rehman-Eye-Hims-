import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../custum widgets/custom_loader.dart';

class MobileDoctorDashboard extends StatefulWidget {
  const MobileDoctorDashboard({super.key});

  @override
  State<MobileDoctorDashboard> createState() => _MobileDoctorDashboardState();
}

class _MobileDoctorDashboardState extends State<MobileDoctorDashboard> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    final authProvider = context.read<MobileAuthProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await authProvider.fetchDoctorAppointments(dateStr);
    
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _appointments = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MobileAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B5AD),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Portal', style: TextStyle(fontSize: 14)),
            Text('Dr. ${user?.fullName ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<MobileAuthProvider>().logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date Selector ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                    _fetchSchedule();
                  },
                ),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _fetchSchedule();
                    }
                  },
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF00B5AD)),
                  label: Text(
                    DateFormat('EEE, MMM d').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                    _fetchSchedule();
                  },
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // ── Appointment List ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CustomLoader(size: 40, color: Color(0xFF00B5AD)))
                : _appointments.isEmpty
                    ? const Center(child: Text('No appointments for this day'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appt = _appointments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(appt['patient_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Time: ${_formatTime(appt['slot_time'])} | Token: ${appt['token_number'] ?? appt['token_no']}'),
                                  const SizedBox(height: 4),
                                  Text('Stat: ${appt['status']}', 
                                    style: TextStyle(color: (appt['status']?.toString().toLowerCase() == 'booked' || appt['status']?.toString().toLowerCase() == 'pending') ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: (appt['status']?.toString().toLowerCase() == 'booked' || appt['status']?.toString().toLowerCase() == 'pending') ? IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00B5AD), size: 32),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Complete Appointment?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    final res = await context.read<MobileAuthProvider>().finishAppointment(appt['appointment_id'].toString());
                                    if (res['success'] == true) _fetchSchedule();
                                  }
                                },
                              ) : const Icon(Icons.check_circle, color: Colors.green),
                            ),
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
    } catch (e) {
      return time;
    }
  }
}
