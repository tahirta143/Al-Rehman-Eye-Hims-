import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    final hPad = screenW * 0.07;
    final headerH = screenH * 0.28;
    final logoSize = screenW * 0.18;
    final logoIconSize = screenW * 0.10;
    final titleFontSize = screenW * 0.062;
    final inputFontSize = screenW * 0.038;
    final btnFontSize = screenW * 0.042;
    final socialBtnSize = screenW * 0.13;

    return Scaffold(
      backgroundColor: const Color(0xFF00B5AD),
      body: Column(
        children: [
          // ── Teal Header ─────────────────────────────────────────────
          SizedBox(
            height: headerH,
            child: SafeArea(
              bottom: false,
              child: Center(
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
            ),
          ),

          // ── White Body ───────────────────────────────────────────────
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
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: screenH * 0.035),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Sign up',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00B5AD),
                      ),
                    ),
                    SizedBox(height: screenH * 0.030),

                    // Full Name
                    _InputField(
                      controller: _fullNameController,
                      hint: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      fontSize: inputFontSize,
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Email
                    _InputField(
                      controller: _emailController,
                      hint: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      fontSize: inputFontSize,
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Phone Number
                    _InputField(
                      controller: _phoneController,
                      hint: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      fontSize: inputFontSize,
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Age and Gender Row
                    Row(
                      children: [
                        // Age Field
                        Expanded(
                          child: _InputField(
                            controller: _ageController,
                            hint: 'Age',
                            prefixIcon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            fontSize: inputFontSize,
                          ),
                        ),
                        SizedBox(width: screenW * 0.03),

                        // Gender Dropdown
                        Expanded(
                          child: _GenderDropdown(
                            value: _selectedGender,
                            items: _genders,
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            fontSize: inputFontSize,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenH * 0.016),

                    // City
                    _InputField(
                      controller: _cityController,
                      hint: 'City',
                      prefixIcon: Icons.location_city_outlined,
                      keyboardType: TextInputType.text,
                      fontSize: inputFontSize,
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Address
                    _InputField(
                      controller: _addressController,
                      hint: 'Address',
                      prefixIcon: Icons.home_outlined,
                      keyboardType: TextInputType.streetAddress,
                      fontSize: inputFontSize,
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Password
                    _InputField(
                      controller: _passwordController,
                      hint: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      fontSize: inputFontSize,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: screenW * 0.045,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.016),

                    // Confirm Password
                    _InputField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirm,
                      fontSize: inputFontSize,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: screenW * 0.045,
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.028),

                    // Sign Up Button
                    SizedBox(
                      height: screenH * 0.062,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle sign up logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B5AD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign up',
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
                          "Already have an account? ",
                          style: TextStyle(
                            fontSize: inputFontSize,
                            color: Colors.grey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
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
                    SizedBox(height: screenH * 0.028),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenW * 0.03),
                          child: Text(
                            'Or Sign Up with',
                            style: TextStyle(
                              fontSize: inputFontSize * 0.9,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      ],
                    ),
                    SizedBox(height: screenH * 0.024),

                    // Social Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialButton(label: 'f', size: socialBtnSize, fontSize: inputFontSize * 1.1),
                        SizedBox(width: screenW * 0.04),
                        _SocialButton(label: 'G', size: socialBtnSize, fontSize: inputFontSize * 1.1),
                        SizedBox(width: screenW * 0.04),
                        _SocialButton(label: 'X', size: socialBtnSize, fontSize: inputFontSize * 1.1),
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

  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.fontSize,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: fontSize),
        prefixIcon: Icon(prefixIcon, color: Colors.grey.shade400, size: fontSize * 1.3),
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
          borderSide: const BorderSide(color: Color(0xFF00B5AD), width: 1.5),
        ),
      ),
    );
  }
}

// ── Gender Dropdown Widget ─────────────────────────────────────────────────────
class _GenderDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final double fontSize;

  const _GenderDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: Colors.grey.shade400,
                  size: fontSize * 1.3,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gender',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.shade400,
              size: fontSize * 1.3,
            ),
          ),
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black87,
          ),
          items: items.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.grey.shade600,
                      size: fontSize * 1.3,
                    ),
                    const SizedBox(width: 8),
                    Text(gender),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((gender) {
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: Colors.grey.shade600,
                      size: fontSize * 1.3,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gender,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

// ── Social Button ─────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final double size;
  final double fontSize;

  const _SocialButton({
    required this.label,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
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
      ..color = const Color(0xFF00B5AD)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(45 * 3.14159265 / 180);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.width * 0.32, height: size.height * 0.82),
        Radius.circular(size.width * 0.16),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.width * 0.82, height: size.height * 0.32),
        Radius.circular(size.height * 0.16),
      ),
      paint,
    );
    canvas.restore();

    final r = size.width * 0.04;
    final o = size.width * 0.22;
    for (final pt in [
      Offset(cx - o, cy - o * 0.5), Offset(cx - o * 0.5, cy - o),
      Offset(cx + o, cy - o * 0.5), Offset(cx + o * 0.5, cy - o),
      Offset(cx - o, cy + o * 0.5), Offset(cx - o * 0.5, cy + o),
      Offset(cx + o, cy + o * 0.5), Offset(cx + o * 0.5, cy + o),
    ]) {
      canvas.drawCircle(pt, r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}