import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../custum widgets/drawer/base_scaffold.dart';
import '../providers/dashboard/dashboard_provider.dart';
import '../providers/opd/consultation_provider/cunsultation_provider.dart';
import 'dashboard/dashboard.dart';
import 'emergency_treatment/emergency_treatment.dart';
import 'cunsultations/cunsultations.dart';
import 'mr_details/mr_details.dart';
import 'add_expenses/add_expenses.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentBtmIndex = 0;

  // The 5 main screens for the bottom navigation
  final List<Widget> _screens = [
    const HomeScreen(useScaffold: false),
    const EmergencyTreatmentScreen(useScaffold: false),
    const ConsultationScreen(useScaffold: false),
    const MrDetailsScreen(useScaffold: false),
    const ExpensesScreen(useScaffold: false),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Emergency Treatment',
    'Consultations',
    'MR Details',
    'Expenses',
  ];

  // Mapping bottom index to drawer index for consistent state
  final List<int> _drawerIndices = [0, 5, 1, 8, 2];

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: _titles[_currentBtmIndex],
      drawerIndex: _drawerIndices[_currentBtmIndex],
      showAppBar: _currentBtmIndex != 1 && _currentBtmIndex != 2,
      onBottomNavTap: (index) {
        if (index == 0) {
          final prov = context.read<DashboardProvider>();
          prov.resetToToday();
          prov.resetLoading();
          prov.refresh();
        } else if (index == 2) {
          final prov = context.read<ConsultationProvider>();
          prov.resetLoading();
          prov.loadDoctors();
          prov.loadAppointments();
        }
        setState(() {
          _currentBtmIndex = index;
        });
      },
      // Using IndexedStack to keep screen states alive and avoid re-build "shaking"
      body: IndexedStack(
        index: _currentBtmIndex,
        children: _screens,
      ),
    );
  }
}
