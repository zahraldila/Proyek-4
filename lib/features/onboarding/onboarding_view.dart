import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logbook_app_094/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  int step = 1;

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _slide = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> nextStep() async {
    await _animCtrl.reverse();

    if (!mounted) return;

    if (step < 3) {
      setState(() => step++);
      await _animCtrl.forward();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
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

  Widget _dot(int index) {
    final isActive = step == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: isActive ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8CC152) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F8FF);
    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ================= GREEN AREA =================
                Expanded(
                  flex: 70, 
                  child: Stack(
                    children: [
                      // background wavy
                      ClipPath(
                        clipper: StrongWaveClipper(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.78, 
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [green1, green2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                      // subtle highlight
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.22,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // SVG content with animation
                      Center(
                        child: AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fade.value,
                              child: Transform.translate(
                                offset: Offset(0, _slide.value),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SvgPicture.asset(
                              getImageForStep(),
                              height: 250,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= WHITE AREA =================
                Expanded(
                  flex: 30,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fade.value,
                              child: Transform.translate(
                                offset: Offset(0, _slide.value),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                getTitleForStep(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                getDescriptionForStep(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.35,
                                  color: bodyColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_dot(1), _dot(2), _dot(3)],
                        ),

                        const Spacer(),

                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ===== floating button =====
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: SizedBox(
                  width: 210,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green2,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        step == 3 ? "Mulai" : "Next",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

// ======================
// WAVY CLIPPER 
// ======================
class StrongWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 90);

    // wave besar 
    path.cubicTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.55,
      size.height - 170,
      size.width * 0.78,
      size.height - 100,
    );

    // wave kecil kanan
    path.cubicTo(
      size.width * 0.90,
      size.height - 60,
      size.width * 0.96,
      size.height - 75,
      size.width,
      size.height - 90,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
