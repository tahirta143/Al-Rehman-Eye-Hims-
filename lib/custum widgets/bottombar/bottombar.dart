import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFluidBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomFluidBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomFluidBottomNavBar> createState() => _CustomFluidBottomNavBarState();
}

class _CustomFluidBottomNavBarState extends State<CustomFluidBottomNavBar>
    with TickerProviderStateMixin {

  static const Color _primary = Color(0xFF00B5AD);
  static const Color _primaryDark = Color(0xFF007A73);

  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late AnimationController _slideController;
  late Animation<double> _slideAnim;
  int _prevIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.dashboard_rounded,     label: 'Dashboard'),
    _NavItem(icon: Icons.warning_amber_rounded, label: 'Emergency'),
    _NavItem(icon: Icons.chat_bubble_rounded,   label: 'Consult'),
    _NavItem(icon: Icons.people_alt_rounded,    label: 'MR Details'),
    _NavItem(icon: Icons.receipt_long_rounded,  label: 'Expenses'),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;

    _controllers = List.generate(_items.length, (i) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 320)));
    _scaleAnims = _controllers.map((c) =>
        Tween<double>(begin: 1.0, end: 1.12).animate(
            CurvedAnimation(parent: c, curve: Curves.easeOutBack))).toList();

    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _controllers[widget.currentIndex].forward();
    _slideController.value = 1.0;
  }

  @override
  @override
  void didUpdateWidget(CustomFluidBottomNavBar old) {
    super.didUpdateWidget(old);

    if (old.currentIndex != widget.currentIndex) {
      _controllers[old.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();

      _prevIndex = old.currentIndex;

      // Reset properly before animating
      _slideController.stop();
      _slideController.reset();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    widget.onItemSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / _items.length;
    // Height of the bar below the notch
    const double barHeight = 76.0;
    // How far the circle floats above the bar top
    const double floatOffset = 20.0;
    const double circleSize = 46.0;

    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (_, __) {
        // Interpolate notch center X between prev and current tab
        final double fromX = _prevIndex * itemWidth + itemWidth / 2;
        final double toX   = widget.currentIndex * itemWidth + itemWidth / 2;
        final double notchX = fromX + (toX - fromX) * _slideAnim.value;

        return SizedBox(
          // Extra height at top so the floating circle has room
          height: barHeight + floatOffset + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              // ── 1. Curved bar (clipped shape) ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBar(notchX, itemWidth, barHeight, width),
              ),

              // ── 2. Floating circle — drawn ON TOP of everything, never clipped ──
              Positioned(
                // Center the circle horizontally on notchX
                left: notchX - circleSize / 2,
                // Float above the bar top
                top: 0,
                child: _buildFloatingCircle(circleSize),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Curved white bar with SafeArea ──
  Widget _buildBar(double notchX, double itemWidth, double barHeight, double width) {
    return Container(
      decoration: BoxDecoration(
        // boxShadow: [
        //   BoxShadow(
        //     color: _primary.withOpacity(0.18),
        //     blurRadius: 28,
        //     offset: const Offset(0, -6),
        //   ),
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.07),
        //     blurRadius: 12,
        //     offset: const Offset(0, -2),
        //   ),
        // ],
      ),
      child: ClipPath(
        clipper: _CurvedNavClipper(notchCenterX: notchX),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: barHeight,
              child: Row(
                children: List.generate(
                  _items.length,
                      (i) => _buildItem(i, itemWidth),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Teal circle that floats in the notch ──
  Widget _buildFloatingCircle(double size) {
    return AnimatedBuilder(
      animation: _controllers[widget.currentIndex],
      builder: (_, __) {
        return ScaleTransition(
          scale: _scaleAnims[widget.currentIndex],
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // boxShadow: [
              //   BoxShadow(
              //     color: _primary.withOpacity(0.30),
              //     blurRadius: 18,
              //     spreadRadius: 0,
              //     offset: const Offset(0, 6),
              //   ),
              // ],
            ),
            child: Center(
              child: Icon(
                _items[widget.currentIndex].icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Individual nav item (unselected tabs) ──
  Widget _buildItem(int index, double itemWidth) {
    final item = _items[index];
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hide icon for selected tab (it's in the floating circle)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isSelected ? 0.0 : 1.0,
              child: Icon(
                item.icon,
                size: 22,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _primary : Colors.grey.shade400,
                letterSpacing: 0.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CURVED CLIPPER
// ─────────────────────────────────────────────
class _CurvedNavClipper extends CustomClipper<Path> {
  final double notchCenterX;

  const _CurvedNavClipper({required this.notchCenterX});

  @override
  Path getClip(Size size) {
    const double notchRadius = 34.0;
    const double notchDepth  = 22.0;
    const double spread      = 48.0;
    const double topRadius   = 22.0;

    final cx = notchCenterX;
    final path = Path();

    // Top-left rounded corner
    path.moveTo(0, topRadius);
    path.quadraticBezierTo(0, 0, topRadius, 0);

    // Flat top → left shoulder of notch
    path.lineTo(cx - spread - 6, 0);

    // Smooth left curve down into notch
    path.cubicTo(
      cx - spread + 8,  0,
      cx - notchRadius, notchDepth,
      cx,               notchDepth,
    );

    // Smooth right curve up out of notch
    path.cubicTo(
      cx + notchRadius, notchDepth,
      cx + spread - 8,  0,
      cx + spread + 6,  0,
    );

    // Flat top → top-right rounded corner
    path.lineTo(size.width - topRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, topRadius);

    // Right side → bottom-right
    path.lineTo(size.width, size.height);

    // Bottom → bottom-left
    path.lineTo(0, size.height);

    // Left side → back to start
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_CurvedNavClipper old) =>
      old.notchCenterX != notchCenterX;
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}