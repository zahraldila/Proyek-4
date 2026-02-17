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

  bool get _isStepValid =>
      _stepError == null && _stepText.text.trim().isNotEmpty;

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
    setState(() => _controller.increment(widget.username));
    await _controller.saveAll(widget.username);
  }

  Future<void> _decrement() async {
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
              child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
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

    final greeting = _getGreeting();

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
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD6E2FF)),
                ),
                child: Text(
                  "$greeting, ${widget.username} 👋",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A44),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Counter Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text("Total Hitungan:"),
                    const SizedBox(height: 8),
                    Text(
                      '${_controller.value}',
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
                      ),
                      onChanged: _validateAndSetStep,
                      onSubmitted: _validateAndSetStep,
                    ),

                    const SizedBox(height: 8),
                    Text("Step saat ini: ${_controller.step}"),

                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: "dec",
                          onPressed: _isStepValid ? _decrement : null,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        FloatingActionButton(
                          heroTag: "inc",
                          onPressed: _isStepValid ? _increment : null,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _resetCounter,
                      child: const Text("Reset"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Riwayat (5 terakhir):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (_controller.history.isEmpty)
                const Text("Belum ada aktivitas.")
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _controller.history.length,
                  itemBuilder: (context, index) {
                    final text = _controller.history[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "• $text",
                        style: TextStyle(color: _historyColor(text)),
                      ),
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
