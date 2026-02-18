import 'package:flutter/material.dart';
import 'package:logbook_app_094/features/logbook/counter_controller.dart';
import 'package:logbook_app_094/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  final String username;

  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _stepText = TextEditingController(text: '1');

  String? _stepError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _controller.loadAll(widget.username);
    _stepText.text = _controller.step.toString();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _stepText.dispose();
    super.dispose();
  }

  // Welcome Banner
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  bool get _isStepValid => _stepError == null && _stepText.text.trim().isNotEmpty;

  Future<void> _validateAndSetStep(String input) async {
    final n = int.tryParse(input);

    if (n == null) {
      setState(() => _stepError = "Step harus berupa angka.");
      return;
    }
    if (n < 1) {
      setState(() => _stepError = "Step tidak boleh 0 atau negatif.");
      return;
    }

    setState(() {
      _stepError = null;
      _controller.setStep(widget.username, n);
    });

    await _controller.saveAll(widget.username);
  }

  Future<void> _increment() async {
    if (!_isStepValid) return;
    setState(() => _controller.increment(widget.username));
    await _controller.saveAll(widget.username);
  }

  Future<void> _decrement() async {
    if (!_isStepValid) return;
    setState(() => _controller.decrement(widget.username));
    await _controller.saveAll(widget.username);
  }

  Future<void> _resetCounter() async {
    setState(() => _controller.reset(widget.username));
    await _controller.saveAll(widget.username);
  }

  Color _historyColor(String text) {
    Color color = const Color(0xFF4A5A7A);
    if (text.contains('+')) {
      color = const Color(0xFF2E7D6B);
    } else if (text.contains('-') || text.toLowerCase().contains('gagal')) {
      color = const Color(0xFFB23A55);
    } else if (text.toLowerCase().contains('reset')) {
      color = const Color(0xFF3B5CCC);
    }
    return color;
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const OnboardingView()),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F8FF);
    const green1 = Color(0xFFA0D468);
    const green2 = Color(0xFF8CC152);

    const titleColor = Color(0xFF1F2A44);
    const bodyColor = Color(0xFF4A5A7A);

    const fieldFill = Color(0xFFEAF7E5); 
    const cardWhite = Color(0xFFFFFFFF);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "LogBook: ${widget.username}",
          style: const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: titleColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ===== header wavy hijau =====
            ClipPath(
              clipper: _HeaderWaveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
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

            // ===== konten =====
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== welcome card =====
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardWhite.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      "$greeting, ${widget.username} 👋",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ===== counter card =====
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardWhite.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Total Hitungan",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: bodyColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${_controller.value}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // step input
                        TextField(
                          controller: _stepText,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2A44),
                          ),
                          decoration: InputDecoration(
                            labelText: "Step",
                            hintText: "Minimal 1",
                            errorText: _stepError,
                            filled: true,
                            fillColor: const Color(0xFFEAF7E5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: _validateAndSetStep,
                          onSubmitted: _validateAndSetStep,
                        ),


                        const SizedBox(height: 8),
                        Text(
                          "Step saat ini: ${_controller.step}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: bodyColor),
                        ),

                        const SizedBox(height: 18),

                        // +/- buttons 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PillIconButton(
                              icon: Icons.remove,
                              enabled: _isStepValid,
                              onTap: _decrement,
                            ),
                            const SizedBox(width: 14),
                            _PillIconButton(
                              icon: Icons.add,
                              enabled: _isStepValid,
                              onTap: _increment,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // reset button
                        SizedBox(
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _resetCounter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green2,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                "Reset",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Riwayat (5 terakhir)",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_controller.history.isEmpty)
                    const Text(
                      "Belum ada aktivitas.",
                      style: TextStyle(color: bodyColor),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardWhite.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(_controller.history.length, (i) {
                          final text = _controller.history[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("•  "),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: _historyColor(text),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PillIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF1F2A44);
    const pillBg = Color(0xFFEAF7E5);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 86,
          height: 64,
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: titleColor),
        ),
      ),
    );
  }
}

// wave header
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 58);

    path.cubicTo(
      size.width * 0.22,
      size.height + 18,
      size.width * 0.65,
      size.height - 120,
      size.width,
      size.height - 58,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
