import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hims_app/screens/cunsultations/consultation_report.dart';
import 'package:hims_app/screens/cunsultations/cunsultations.dart';
import 'package:hims_app/screens/discount_vouchers/discount_vouchers.dart';
import 'package:hims_app/screens/emergency_treatment/emergency_treatment.dart';
import 'package:hims_app/screens/mr_details/mr_details.dart';
import 'package:hims_app/screens/mr_details/mr_view/mr_view.dart';
import 'package:hims_app/screens/opd_reciepts/opd_reciept.dart';
import 'package:hims_app/screens/opd_reciepts/opd_records.dart';
import 'package:hims_app/screens/consultation_payments/consultation_payments.dart'
    hide TextStyle;
import 'package:hims_app/screens/shift_management/shift_management.dart';
import '../../screens/add_expenses/add_expenses.dart';
import '../../screens/dashboard/dashboard.dart';
import '../../custum widgets/bottombar/bottombar.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../screens/prescription/fundus_examination_screen.dart';
import '../../screens/prescription/nutrition_screen.dart';
import '../../screens/prescription/prescription.dart';
import '../../screens/prescription/lab_values.dart';
import '../../screens/prescription/eye_prescription.dart';
import '../../screens/prescription/vitals.dart';
import '../../screens/prescription/lab_values.dart';
import '../../screens/pharmacy_screens/add_modify_medicines_screen.dart';
import '../../screens/pharmacy_screens/opening_balances_screen.dart';
import '../../screens/pharmacy_screens/purchase_posting_screen.dart';
import '../../screens/pharmacy_screens/sales_invoice_screen.dart';
import 'drawer.dart';
import '../../custum widgets/ai_chat_widget.dart';

// ─── FIX: Convert BaseScaffold from StatelessWidget to StatefulWidget ─────────
//
// ROOT CAUSE of the keyboard bug:
//   BaseScaffold was a StatelessWidget, so its build() ran on every parent
//   setState(). Inside build() it did:
//
//     final effectiveKey = scaffoldKey ?? GlobalKey<ScaffoldState>();
//
//   This created a BRAND NEW GlobalKey on every build. Flutter sees a new key
//   → treats the Scaffold as a completely new widget → tears down and recreates
//   the IME (keyboard) connection → keyboard flickers hide/show on every
//   keystroke in the child form.
//
// FIX: Move the fallback GlobalKey into State so it is created exactly once
//   and survives rebuilds.
// ─────────────────────────────────────────────────────────────────────────────

class BaseScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final int drawerIndex;
  final bool showAppBar;
  final bool showNotificationIcon;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  static const Color primaryColor = Color(0xFF00B5AD);

  const BaseScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.drawerIndex,
    this.showAppBar = true,
    this.showNotificationIcon = true,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.scaffoldKey,
    this.onBottomNavTap,
  });

  final Function(int)? onBottomNavTap;

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  // ✅ Created once in State — survives every rebuild triggered by child setState()
  late final GlobalKey<ScaffoldState> _fallbackKey;

  @override
  void initState() {
    super.initState();
    _fallbackKey = GlobalKey<ScaffoldState>();
  }

  GlobalKey<ScaffoldState> get _effectiveKey =>
      widget.scaffoldKey ?? _fallbackKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _effectiveKey,
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true, // Allows content to flow behind the bottom bar

      drawer: CustomDrawer(
        selectedIndex: widget.drawerIndex,
        onMenuItemTap: (index) {
          Navigator.pop(context);
          if (index != widget.drawerIndex) {
            _navigateToScreen(context, index);
          }
        },
      ),

      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar ?? _buildBottomNavBar(),

      body: Stack(
        children: [
          Column(
            children: [
              if (widget.showAppBar) _buildHeader(context, _effectiveKey),
              Expanded(child: widget.body),
            ],
          ),
          const AiChatWidget(),
        ],
      ),
    );
  }

  Widget? _buildBottomNavBar() {
    // Map drawer indices to bottom bar indices
    // Bottom Bar Items: 0: Dashboard, 1: Emergency, 2: Consult, 3: MR View, 4: Expenses
    // Drawer Indices mapping:
    // 0: Dashboard -> 0
    // 5: Emergency -> 1
    // 1, 3, 4, 6, 7, 10, 11 (OPD/Consultation Related) -> 2
    // 8, 9 (MR Related) -> 3
    // 2 (Expenses) -> 4

    int btmIndex = 0; // Default to Dashboard (index 0)

    if (widget.drawerIndex == 0) {
      btmIndex = 0; // Dashboard
    } else if (widget.drawerIndex == 5) {
      btmIndex = 1; // Emergency
    } else if (widget.drawerIndex == 1) {
      btmIndex = 2; // Consultation Appointment
    } else if (widget.drawerIndex == 8) {
      btmIndex = 3; // MR Details
    } else if (widget.drawerIndex == 2) {
      btmIndex = 4; // Add Expenses
    } else {
      btmIndex = 0; // Default all other drawer items to Dashboard
    }

    return CustomFluidBottomNavBar(
      currentIndex: btmIndex,
      onItemSelected: (index) {
        if (index == btmIndex &&
            (index == 0 || index == 1 || index == 3 || index == 4)) {
          // If we are already on a primary screen of this tab, do nothing
          // For Consult (index 2), we might want to navigate to the main Consult screen (index 1)
          // if we are currently on a sub-screen like OPD records.
          return;
        }

        if (widget.onBottomNavTap != null) {
          widget.onBottomNavTap!(index);
          return;
        }

        // Map back to drawer indices for navigation
        int drawerIndex = 0;
        if (index == 0) drawerIndex = 0;
        else if (index == 1) drawerIndex = 5;
        else if (index == 2) drawerIndex = 1;
        else if (index == 3) drawerIndex = 8;
        else if (index == 4) drawerIndex = 2;

        _navigateToScreen(context, drawerIndex);
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BaseScaffold.primaryColor, BaseScaffold.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Menu button
              GestureDetector(
                onTap: () => scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.actions != null) ...widget.actions!,
              if (widget.showNotificationIcon && widget.actions == null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
              ],
            ],
          ),
          if (widget.title == 'Dashboard')
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 4),
              child: Consumer<PermissionProvider>(
                builder: (context, perm, child) {
                  final name = perm.fullName ?? 'User';
                  return Text(
                    'Good morning, $name 👋',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const ConsultationScreen();
        break;
      case 2:
        screen = const ExpensesScreen();
        break;
      case 3:
        screen = const OpdReceiptScreen();
        break;
      case 4:
        screen = const OpdRecordsScreen();
        break;
      case 5:
        screen = const EmergencyTreatmentScreen();
        break;
      case 6:
        screen = const ConsultantPaymentsScreen();
        break;
      case 7:
        screen = const ShiftManagementScreen();
        break;
      case 8:
        screen = const MrDetailsScreen();
        break;
      case 9:
        screen = const PrescriptionScreen();
        break;
      case 12:
        screen = const EyePrescriptionScreen();
        break;
      case 10:
        screen = const DiscountVoucherApprovalScreen();
        break;
      case 11:
        screen = const AppointmentReportScreen();
        break;
      case 13:
        screen = const VitalsScreen();
        break;
      case 14:
        screen = const LabValuesScreen();
        break;
      case 15:
        screen = const NutritionScreen();
        break;
      case 16:
        screen = const FundusExaminationScreen();
        break;
      case 17:
        screen = const AddModifyMedicinesScreen();
        break;
      case 18:
        screen = const OpeningBalancesScreen();
        break;
      case 19:
        screen = const PurchasePostingScreen();
        break;
      case 20:
        screen = const SalesInvoiceScreen();
        break;
      case -1:
        _showLogoutDialog(context);
        return;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/SignInScreen'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}