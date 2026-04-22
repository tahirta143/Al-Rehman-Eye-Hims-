import 'package:flutter/material.dart';

import '../auth/login.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

const List<OnboardingData> onboardingPages = [
  OnboardingData(
    title: 'Find Your Trusted\nSpecialist',
    subtitle: 'A wide network of certified doctors and specialists',
    imagePath: 'assets/images/onboard4.png',
  ),
  OnboardingData(
    title: 'Consult Anytime,\nAnywhere',
    subtitle: 'Connect with medical experts instantly via video call.',
    imagePath: 'assets/images/onboard2.png',
  ),
  OnboardingData(
    title: 'Easy Appointment\nBooking',
    subtitle: 'Schedule your visit with just a few taps, anytime.',
    imagePath: 'assets/images/onboard3.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page → navigate to login/home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── MediaQuery ─────────────────────────────────────────────────────────
    final mq        = MediaQuery.of(context);
    final screenH   = mq.size.height;
    final screenW   = mq.size.width;

    // Responsive values derived from screen dimensions - REDUCED ALL VALUES
    final hPad            = screenW * 0.06;    // horizontal page padding (keep same)
    final cardRadius      = screenW * 0.04;    // REDUCED border radius
    final titleFontSize   = screenW * 0.048;   // REDUCED font size (was 0.062)
    final subtitleFontSize= screenW * 0.03;    // REDUCED font size (was 0.036)
    final cardHPad        = screenW * 0.04;    // REDUCED horizontal padding (was 0.06)
    final cardVPad        = screenH * 0.016;   // REDUCED vertical padding (was 0.026)
    final gapBelowCard    = screenH * 0.015;   // REDUCED gap (was 0.025)
    final dotBarH         = screenH * 0.05;    // REDUCED dot bar height (was 0.07)
    final dotH            = screenH * 0.008;   // REDUCED dot height (was 0.011)
    final dotActiveW      = screenW * 0.045;   // REDUCED active dot width (was 0.065)
    final dotInactiveW    = screenW * 0.015;   // REDUCED inactive dot width (was 0.022)
    final titleSubtitleGap = screenH * 0.006;  // ADDED smaller gap between title and subtitle
    final bottomPadding    = screenH * 0.01;   // ADDED smaller bottom padding
    // ───────────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // light-grey app bg
      body: SafeArea(
        child: Column(
          children: [
            // ── PageView ───────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: onboardingPages[index],
                    hPad: hPad,
                    cardRadius: cardRadius,
                    cardHPad: cardHPad,
                    cardVPad: cardVPad,
                    gapBelowCard: gapBelowCard,
                    titleFontSize: titleFontSize,
                    subtitleFontSize: subtitleFontSize,
                    screenH: screenH,
                    titleSubtitleGap: titleSubtitleGap,
                    bottomPadding: bottomPadding,
                    onTap: _nextPage,
                  );
                },
              ),
            ),

            // ── Dot Indicators ─────────────────────────────────────────────
            SizedBox(
              height: dotBarH,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingPages.length,
                      (i) => _DotIndicator(
                    isActive: i == _currentPage,
                    activeW: dotActiveW,
                    inactiveW: dotInactiveW,
                    height: dotH,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single Onboarding Page ─────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final double hPad;
  final double cardRadius;
  final double cardHPad;
  final double cardVPad;
  final double gapBelowCard;
  final double titleFontSize;
  final double subtitleFontSize;
  final double screenH;
  final double titleSubtitleGap;
  final double bottomPadding;
  final VoidCallback onTap;

  const _OnboardingPage({
    required this.data,
    required this.hPad,
    required this.cardRadius,
    required this.cardHPad,
    required this.cardVPad,
    required this.gapBelowCard,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.screenH,
    required this.titleSubtitleGap,
    required this.bottomPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── White Speech-Bubble Card (Tappable) ─────────────────────────
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: cardHPad,
                vertical: cardVPad,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10, // REDUCED blur radius
                    offset: const Offset(0, 2), // REDUCED offset
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // ADDED - makes card take minimum height
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00B5AD),
                      height: 1.2, // REDUCED line height (was 1.3)
                    ),
                  ),
                  SizedBox(height: titleSubtitleGap), // USING smaller gap
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: const Color(0xFFAAAAAA),
                      height: 1.3, // REDUCED line height (was 1.55)
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: gapBelowCard),

          // ── Grey Image Placeholder (Tappable) ───────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDFDFDF),
                  borderRadius: BorderRadius.circular(cardRadius),
                ),
                clipBehavior: Clip.hardEdge,
                child: _AssetImageWithFallback(imagePath: data.imagePath),
              ),
            ),
          ),

          SizedBox(height: bottomPadding), // USING smaller bottom padding
        ],
      ),
    );
  }
}

// ── Asset Image with Grey Fallback ────────────────────────────────────────────
class _AssetImageWithFallback extends StatelessWidget {
  final String imagePath;
  const _AssetImageWithFallback({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFDFDFDF),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 40, // REDUCED icon size (was 64)
              color: Color(0xFFBBBBBB),
            ),
          ),
        );
      },
    );
  }
}

// ── Dot Indicator ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final double activeW;
  final double inactiveW;
  final double height;

  const _DotIndicator({
    required this.isActive,
    required this.activeW,
    required this.inactiveW,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: inactiveW * 0.25), // REDUCED margin
      width: isActive ? activeW : inactiveW,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00B5AD) : const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}