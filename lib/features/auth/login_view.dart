import 'dart:async';
import 'package:flutter/material.dart';

import 'package:logbook_app_094/features/auth/login_controller.dart';
import 'package:logbook_app_094/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockSecondsLeft = 0;
  Timer? _lockTimer;

  // Poin 3: show/hide password
  bool _obscurePass = true;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _startLock() {
    _isLocked = true;
    _lockSecondsLeft = 10;

    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() {
        _lockSecondsLeft--;
      });

      if (_lockSecondsLeft <= 0) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          _isLocked = false;
          _failedAttempts = 0; // reset kesempatan setelah lock selesai
        });
      }
    });
  }

  void _handleLogin() {
    if (_isLocked) return;

    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    // Validasi kosong
    if (user.isEmpty || pass.isEmpty) {
      _showSnack("Username dan Password tidak boleh kosong!");
      return;
    }

    final isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      _failedAttempts = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CounterView(username: user),
        ),
      );
      return;
    }

    // Gagal login
    _failedAttempts++;
    _showSnack("Login gagal! (${_failedAttempts}/3)");

    if (_failedAttempts >= 3) {
      setState(() {
        _startLock();
      });
      _showSnack("Terlalu banyak percobaan. Coba lagi 10 detik.");
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = _isLocked ? "Tunggu $_lockSecondsLeft dtk" : "Masuk";

    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
              enabled: !_isLocked,
            ),
            TextField(
              controller: _passController,
              obscureText: _obscurePass, // <-- toggle di sini
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  onPressed: _isLocked
                      ? null
                      : () {
                          setState(() {
                            _obscurePass = !_obscurePass;
                          });
                        },
                  icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              enabled: !_isLocked,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLocked ? null : _handleLogin,
                child: Text(buttonText),
              ),
            ),

            const SizedBox(height: 8),

            if (!_isLocked)
              Text(
                "Sisa percobaan: ${3 - _failedAttempts}",
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
