import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../global/global_api.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../providers/opd/consultation_provider/cunsultation_provider.dart';
import '../../models/consultation_model/doctor_model.dart';
import '../../custum widgets/custom_loader.dart';
import '../auth/login.dart';
import 'my_appointments_screen.dart';
import 'widgets/patient_appointment_dialog.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<String> _departments = [];
  String? _selectedDepartment;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authProvider = context.read<MobileAuthProvider>();
    final consultationProvider = context.read<ConsultationProvider>();
    
    // Departments still from auth provider as it seems more global
    final deptsResult = await authProvider.fetchDepartments();
    
    // Doctors and slots now managed by ConsultationProvider for parity
    // IMPORTANT: Use isPublic: true for the patient portal!
    await consultationProvider.loadDoctors(isPublic: true);
    await consultationProvider.loadAppointments(isPublic: true);

    if (mounted) {
      setState(() {
        if (deptsResult['success'] == true) {
          _departments = List<String>.from(deptsResult['data'] ?? []);
        }
        _isLoading = false;
      });
    }
  }

  void _showBookingDialog(DoctorInfo doctor) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PatientAppointmentDialog(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MobileAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B5AD),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HIMS Patient Portal', style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text('Hello, ${user?.fullName ?? 'Patient'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'My Appointments',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              context.read<MobileAuthProvider>().logout();
              // Navigate back to the very first screen (Staff Login)
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()), 
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF00B5AD),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search doctors or specialties...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00B5AD)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'All Doctors',
                        isSelected: _selectedDepartment == null,
                        onTap: () {
                          setState(() => _selectedDepartment = null);
                        },
                      ),
                      ..._departments.map((dept) => _FilterChip(
                        label: dept,
                        isSelected: _selectedDepartment == dept,
                        onTap: () {
                          setState(() => _selectedDepartment = dept);
                        },
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Doctor List ────────────────────────────────────────────────────
          Expanded(
            child: Consumer<ConsultationProvider>(
              builder: (context, prov, child) {
                if (prov.isLoading && prov.doctors.isEmpty) {
                  return const Center(child: CustomLoader(size: 50, color: Color(0xFF00B5AD)));
                }

                // Filtering logic
                final filteredDoctors = prov.doctors.where((doc) {
                  final matchesDept = _selectedDepartment == null || doc.department == _selectedDepartment;
                  final matchesSearch = _searchQuery.isEmpty || 
                      doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      doc.specialty.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesDept && matchesSearch;
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    // Pull to refresh should reload everything
                    await prov.loadDoctors(isPublic: true);
                    await prov.loadAppointments(isPublic: true);
                  },
                  child: filteredDoctors.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    (prov.errorMessage?.contains('Session expired') ?? false) 
                                        ? Icons.lock_clock_rounded 
                                        : Icons.person_off_rounded, 
                                    size: 60, 
                                    color: Colors.grey.shade300
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    prov.errorMessage ?? 'No doctors found',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 24),
                                  if (prov.errorMessage?.contains('Session expired') ?? false) 
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.read<MobileAuthProvider>().logout();
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const SignInScreen()), 
                                          (route) => false,
                                        );
                                      },
                                      icon: const Icon(Icons.login_rounded),
                                      label: const Text('Go to Login'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00B5AD),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    )
                                  else if (prov.errorMessage != null)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        prov.loadDoctors(isPublic: true);
                                        prov.loadAppointments(isPublic: true);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Try Again'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00B5AD),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = filteredDoctors[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _DoctorCard(
                                doctor: doctor,
                                onTap: () => _showBookingDialog(doctor),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00B5AD) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorInfo doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cw = constraints.maxWidth;
      final Color baseColor = doctor.avatarColor;

      // Extract current dates for the schedule highlight
      final now = DateTime.now();
      final List<DateTime> weekDates = List.generate(7, (i) => now.add(Duration(days: i)));
      final List<String> shortDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Main Card Body ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(130, 16, 16, 16), // Large left pad for image
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.specialty,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consultation Fee',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                ),
                                Text(
                                  'PKR ${doctor.consultationFee}',
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF00B5AD).withOpacity(0.1),
                                    shape: BoxShape.circle
                                ),
                                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00B5AD), size: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // ── Bottom Section: Schedule ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        constraints: BoxConstraints(minWidth: cw - 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Schedule',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ...weekDates.map((date) {
                              final dayName = shortDayNames[date.weekday - 1];
                              final isAvailable = doctor.availableDays.contains(dayName);
                              return Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: isAvailable ? const Color(0xFF00B5AD) : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isAvailable ? const Color(0xFF00B5AD) : Colors.grey.shade200),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isAvailable ? Colors.white : Colors.grey.shade400,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Popping Doctor Image ──
            Positioned(
              left: 16,
              top: -15, 
              bottom: 53, // Touches the schedule section top border
              child: Hero(
                tag: 'doc_${doctor.id}',
                child: Container(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Builder(
                      builder: (context) {
                        final url = GlobalApi.getImageUrl(doctor.imageAsset);
                        if (url != null) {
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder: (_, __) => _buildAvatarFallback(baseColor),
                            errorWidget: (_, __, ___) => _buildAvatarFallback(baseColor),
                          );
                        }
                        return _buildAvatarFallback(baseColor);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvatarFallback(Color primaryColor) {
    return Container(
      width: 100,
      height: 100,
      color: primaryColor.withOpacity(0.1),
      child: Icon(Icons.person, size: 50, color: primaryColor),
    );
  }
}
