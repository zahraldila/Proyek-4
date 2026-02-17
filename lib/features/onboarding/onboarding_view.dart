import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logbook_app_094/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

  void nextStep() {
    if (step < 3) {
      setState(() => step++);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  String getImageForStep() {
    switch (step) {
      case 1:
        return 'assets/images/onboard1.svg';
      case 2:
        return 'assets/images/onboard2.svg';
      case 3:
        return 'assets/images/onboard3.svg';
      default:
        return 'assets/images/onboard1.svg';
    }
  }

  String getTitleForStep() {
    switch (step) {
      case 1:
        return "Catat Aktivitasmu";
      case 2:
        return "Pantau Perkembangan";
      case 3:
        return "Capai Targetmu";
      default:
        return "";
    }
  }

  String getDescriptionForStep() {
    switch (step) {
      case 1:
        return "Catat setiap aktivitas harian dengan mudah.";
      case 2:
        return "Lihat progresmu secara real-time.";
      case 3:
        return "Jadi lebih produktif dan capai tujuanmu.";
      default:
        return "";
    }
  }

  Widget _buildIndicatorDot(int index, {Color activeColor = const Color(0xFF7AA7FF)}) {
    final isActive = step == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 14 : 9,
      height: isActive ? 14 : 9,
      decoration: BoxDecoration(
        color: isActive ? activeColor : activeColor.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text("Onboarding"),
        backgroundColor: const Color(0xFFF6F8FF),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),

            // SVG
            Center(
              child: SvgPicture.asset(
                getImageForStep(),
                height: 260,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              getTitleForStep(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2A44),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              getDescriptionForStep(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5A7A),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicatorDot(1),
                _buildIndicatorDot(2),
                _buildIndicatorDot(3),
              ],
            ),

            const SizedBox(height: 26),

            // Button
            ElevatedButton(
              onPressed: nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1F2A44),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(step == 3 ? "Mulai" : "Next"),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
