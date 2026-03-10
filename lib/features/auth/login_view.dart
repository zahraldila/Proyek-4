import 'package:flutter/material.dart';
import 'package:logbook_app_094/features/auth/login_controller.dart';
import 'package:logbook_app_094/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _obscure = true;

  int _failedAttempts = 0;
  bool _locked = false;
  int _lockSecondsLeft = 0;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _lockFor10Seconds() async {
    setState(() {
      _locked = true;
      _lockSecondsLeft = 10;
    });

    for (int i = 10; i >= 1; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _lockSecondsLeft = i - 1);
    }

    if (!mounted) return;
    setState(() {
      _locked = false;
      _failedAttempts = 0;
      _lockSecondsLeft = 0;
    });
  }

  Future<void> _handleLogin() async {
    if (_locked) return;

    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _failedAttempts++);
    } else {
      final userData = _controller.login(user, pass);

      if (userData != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LogView(currentUser: userData),
          ),
        );
        return;
      } else {
        setState(() => _failedAttempts++);
      }
    }

    if (_failedAttempts >= 3) {
      await _lockFor10Seconds();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F8FF);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);

    const fieldFill = Color(0xFFEAF7E5);
    const errorRed = Color(0xFFB23A55);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.34,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Welcome back 👋",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Silakan isi username dan password.",
                            style: TextStyle(color: bodyColor),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _userController,
                            decoration: InputDecoration(
                              labelText: "Username",
                              filled: true,
                              fillColor: fieldFill,
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _passController,
                            obscureText: _obscure,
                            onSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: "Password",
                              filled: true,
                              fillColor: fieldFill,
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (_locked)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "Terlalu banyak percobaan. Coba lagi dalam $_lockSecondsLeft detik.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: errorRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                          SizedBox(
                            height: 52,
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
                                onPressed: _locked ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green2,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: Text(
                                  _locked
                                      ? "Tunggu $_lockSecondsLeft dtk"
                                      : "Masuk",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: _locked
                                        ? Colors.grey.shade700
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (_failedAttempts > 0 && !_locked)
                            Text(
                              "Percobaan gagal: $_failedAttempts / 3",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: bodyColor,
                                fontSize: 12.5,
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (_failedAttempts > 0 && !_locked)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: errorRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Login gagal. Periksa kembali username dan password.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 55);

    path.cubicTo(
      size.width * 0.25,
      size.height + 20,
      size.width * 0.65,
      size.height - 120,
      size.width,
      size.height - 55,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}