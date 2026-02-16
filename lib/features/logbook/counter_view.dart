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
    await _controller.loadAll();

    // sinkronkan textfield dengan step tersimpan
    _stepText.text = _controller.step.toString();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _stepText.dispose();
    super.dispose();
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

    await _controller.saveAll();
  }

  Future<void> _increment() async {
    setState(() => _controller.increment(widget.username));
    await _controller.saveAll();
  }

  Future<void> _decrement() async {
    setState(() => _controller.decrement(widget.username));
    await _controller.saveAll();
  }

  Future<void> _resetCounter() async {
    setState(() => _controller.reset(widget.username));
    await _controller.saveAll();
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
          backgroundColor: const Color(0xFFF6F8FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(
              color: Color(0xFF1F2A44),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
            style: TextStyle(color: Color(0xFF4A5A7A)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3B5CCC),
              ),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: Text("LogBook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Selamat Datang, ${widget.username}!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4A5A7A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Total Hitungan:", textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      '${_controller.value}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _stepText,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Step (minimal 1)",
                        errorText: _stepError,
                        filled: true,
                        fillColor: const Color(0xFFF1F5FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFD6E2FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF7AA7FF),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (v) => _validateAndSetStep(v),
                      onSubmitted: (v) => _validateAndSetStep(v),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Step saat ini: ${_controller.step}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF4A5A7A)),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: "dec",
                          backgroundColor: const Color(0xFFFFD6E0),
                          foregroundColor: const Color(0xFF7A1F35),
                          onPressed: _isStepValid ? _decrement : null,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          heroTag: "inc",
                          backgroundColor: const Color(0xFFD6E7FF),
                          foregroundColor: const Color(0xFF1F2A44),
                          onPressed: _isStepValid ? _increment : null,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    if (!_isStepValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          "Perbaiki nilai Step dulu untuk memakai tombol +/-",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB23A55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7AA7FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFF6F8FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: const Text(
                                "Konfirmasi Reset",
                                style: TextStyle(
                                  color: Color(0xFF1F2A44),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: const Text(
                                "Reset akan menghapus nilai dan riwayat aktivitas. Lanjutkan?",
                                style: TextStyle(color: Color(0xFF4A5A7A)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF3B5CCC),
                                  ),
                                  child: const Text("Batal"),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF7AA7FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text("Reset"),
                                ),
                              ],
                            ),
                          );

                          if (ok == true) {
                            await _resetCounter();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF1F2A44),
                                  content: const Text("Counter berhasil di-reset"),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text("Reset"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Riwayat (5 terakhir):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 8),

              if (_controller.history.isEmpty)
                const Text(
                  "Belum ada aktivitas.",
                  style: TextStyle(color: Color(0xFF4A5A7A)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.history.length,
                  itemBuilder: (context, index) {
                    final text = _controller.history[index];
                    final color = _historyColor(text);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text("• $text", style: TextStyle(color: color)),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
