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
    if (step == 1 || step == 2) {
      setState(() {
        step++;
      });
      return;
    }

    if (step == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Onboarding")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ==== FIX CENTER SVG ====
            SizedBox(
              width: double.infinity,
              child: Center(
                child: SvgPicture.asset(
                  getImageForStep(),
                  height: 250,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
            // ========================

            const SizedBox(height: 30),
            Text(
              getTitleForStep(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              getDescriptionForStep(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: nextStep,
              child: Text(step == 3 ? "Mulai" : "Next"),
            ),
          ],
        ),
      ),
    );
  }
}
