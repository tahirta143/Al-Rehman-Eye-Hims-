import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mobile_auth_provider.dart';
import '../../models/mobile_auth_models.dart';
import '../../custum widgets/custom_loader.dart';
import '../patient/patient_dashboard.dart';

class MobileSignUpScreen extends StatefulWidget {
  const MobileSignUpScreen({super.key});

  @override
  State<MobileSignUpScreen> createState() => _MobileSignUpScreenState();
}

class _MobileSignUpScreenState extends State<MobileSignUpScreen> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController  = TextEditingController();
  final _ageController   = TextEditingController();
  final _otpController   = TextEditingController();
  String? _gender;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor:
        isError ? Colors.red.shade600 : const Color(0xFF00B5AD),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final authProvider = context.read<MobileAuthProvider>();
    final phone = _phoneController.text.trim();

    if (authProvider.otpSent) {
      final otp = _otpController.text.trim();
      if (otp.isEmpty) {
        _showSnackBar('Please enter the OTP', isError: true);
        return;
      }
      final result = await authProvider.verifyOTP(phone, otp);
      if (result['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PatientDashboard()),
              (_) => false,
        );
      } else {
        _showSnackBar(result['message'] ?? 'Verification failed', isError: true);
      }
      return;
    }

    if (_nameController.text.isEmpty || phone.isEmpty) {
      _showSnackBar('Name and Phone are required', isError: true);
      return;
    }

    final request = PatientRegisterRequest(
      fullName: _nameController.text.trim(),
      phone: phone,
      gender: _gender,
      city: _cityController.text.trim(),
      age: _ageController.text.trim(),
    );

    final result = await authProvider.register(request);
    if (result['success'] == true) {
      _showSnackBar('OTP sent to your WhatsApp!');
    } else {
      _showSnackBar(result['message'] ?? 'Registration failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq            = MediaQuery.of(context);
    final screenW       = mq.size.width;
    final screenH       = mq.size.height;
    final hPad          = screenW * 0.07;
    final headerH       = screenH * 0.28;
    final logoSize      = screenW * 0.18;
    final logoIconSize  = screenW * 0.10;
    final titleFontSize = screenW * 0.062;
    final inputFontSize = screenW * 0.038;
    final btnFontSize   = screenW * 0.042;

    final authProvider = context.watch<MobileAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF00B5AD),
      body: Column(
        children: [
          // ── Teal Header ──────────────────────────────────────────────────
          SizedBox(
            height: headerH,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  ),
                  // Logo + name centered
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.20),
                          ),
                          child: Center(
                            child: CustomPaint(
                              size: Size(logoIconSize, logoIconSize),
                              painter: _BandagePainter(),
                            ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.012),
                        Text(
                          'HIMS',
                          style: TextStyle(
                            fontSize: screenW * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White Body ───────────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: hPad, vertical: screenH * 0.030),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      authProvider.otpSent ? 'Verify OTP' : 'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00B5AD),
                      ),
                    ),
                    SizedBox(height: screenH * 0.008),
                    Text(
                      authProvider.otpSent
                          ? 'Enter the 6-digit code sent to your WhatsApp'
                          : 'Fill in your details to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: inputFontSize * 0.95,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(height: screenH * 0.022),

                    // ── Registration Fields ──────────────────────────────
                    if (!authProvider.otpSent) ...[
                      _InputField(
                        controller: _nameController,
                        hint: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        fontSize: inputFontSize,
                      ),
                      SizedBox(height: screenH * 0.016),
                      _InputField(
                        controller: _phoneController,
                        hint: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        fontSize: inputFontSize,
                      ),
                      SizedBox(height: screenH * 0.016),

                      // Gender + Age row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _DropdownField(
                              value: _gender,
                              hint: 'Gender',
                              prefixIcon: Icons.people_outline,
                              fontSize: inputFontSize,
                              items: ['Male', 'Female', 'Other'],
                              onChanged: (val) =>
                                  setState(() => _gender = val),
                            ),
                          ),
                          SizedBox(width: screenW * 0.03),
                          Expanded(
                            flex: 1,
                            child: _InputField(
                              controller: _ageController,
                              hint: 'Age',
                              prefixIcon: Icons.calendar_today_outlined,
                              keyboardType: TextInputType.number,
                              fontSize: inputFontSize,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenH * 0.016),
                      _InputField(
                        controller: _cityController,
                        hint: 'City',
                        prefixIcon: Icons.location_city_outlined,
                        fontSize: inputFontSize,
                      ),
                    ]

                    // ── OTP Field ────────────────────────────────────────
                    else ...[
                      _InputField(
                        controller: _otpController,
                        hint: 'Verification Code',
                        prefixIcon: Icons.sms_outlined,
                        keyboardType: TextInputType.number,
                        fontSize: inputFontSize,
                        maxLength: 6,
                      ),
                    ],

                    SizedBox(height: screenH * 0.028),

                    // Submit Button
                    SizedBox(
                      height: screenH * 0.062,
                      child: ElevatedButton(
                        onPressed:
                        authProvider.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B5AD),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF00B5AD).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const CustomLoader(size: 22, color: Colors.white)
                            : Text(
                          authProvider.otpSent
                              ? 'Verify & Finish'
                              : 'Sign Up',
                          style: TextStyle(
                            fontSize: btnFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.022),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                              fontSize: inputFontSize, color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: inputFontSize,
                              color: const Color(0xFF00B5AD),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Input Field ───────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final double fontSize;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLength;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.fontSize,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.enabled = true,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLength: maxLength,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        hintStyle:
        TextStyle(color: Colors.grey.shade400, fontSize: fontSize * 0.95),
        prefixIcon: Icon(prefixIcon,
            color: Colors.grey.shade400, size: fontSize * 1.3),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF00B5AD), width: 1.5),
        ),
      ),
    );
  }
}

// ── Reusable Dropdown Field ────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData prefixIcon;
  final double fontSize;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.fontSize,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400, size: fontSize * 1.3),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: fontSize * 0.95),
          prefixIcon: Icon(prefixIcon,
              color: Colors.grey.shade400, size: fontSize * 1.3),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF00B5AD), width: 1.5),
          ),
        ),
        style: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF1A2340)),
        dropdownColor: Colors.white,
        items: items
            .map((g) => DropdownMenuItem(
            value: g,
            child: Text(g, style: TextStyle(fontSize: fontSize))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Bandage Icon Painter ───────────────────────────────────────────────────────
class _BandagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(45 * 3.14159265 / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.32,
            height: size.height * 0.82),
        Radius.circular(size.width * 0.16),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.82,
            height: size.height * 0.32),
        Radius.circular(size.height * 0.16),
      ),
      paint,
    );
    canvas.restore();

    final r = size.width * 0.04;
    final o = size.width * 0.22;
    for (final pt in [
      Offset(cx - o, cy - o * 0.5),
      Offset(cx - o * 0.5, cy - o),
      Offset(cx + o, cy - o * 0.5),
      Offset(cx + o * 0.5, cy - o),
      Offset(cx - o, cy + o * 0.5),
      Offset(cx - o * 0.5, cy + o),
      Offset(cx + o, cy + o * 0.5),
      Offset(cx + o * 0.5, cy + o),
    ]) {
      canvas.drawCircle(pt, r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}