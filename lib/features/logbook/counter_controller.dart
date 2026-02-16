import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  static const String _keyCounter = 'last_counter';
  static const String _keyStep = 'last_step';
  static const String _keyHistory = 'history_list';

  // ==============================
  //  LOAD SEMUA
  // ==============================
  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt(_keyCounter) ?? 0;
    _step = prefs.getInt(_keyStep) ?? 1;

    final savedHistory = prefs.getStringList(_keyHistory) ?? [];
    _history
      ..clear()
      ..addAll(savedHistory);
  }

  // ==============================
  //  SAVE SEMUA
  // ==============================
  Future<void> saveAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyCounter, _counter);
    await prefs.setInt(_keyStep, _step);
    await prefs.setStringList(_keyHistory, _history);
  }

  // ==============================
  // HISTORY LOG WITH USERNAME
  // ==============================

  void setStep(String username, int newStep) {
    if (newStep < 1) return;
    _step = newStep;
    _addHistory(username, "mengubah step menjadi $_step");
  }

  void increment(String username) {
    _counter += _step;
    _addHistory(username, "menambah +$_step (total: $_counter)");
  }

  void decrement(String username) {
    if (_counter == 0) {
      _addHistory(username, "gagal decrement (counter sudah 0)");
      return;
    }

    final before = _counter;
    _counter -= _step;
    if (_counter < 0) _counter = 0;

    final actual = before - _counter;
    _addHistory(username, "mengurangi -$actual (total: $_counter)");
  }

  void reset(String username) {
    _counter = 0;
    _addHistory(username, "reset (total: $_counter)");
  }

  void _addHistory(String username, String action) {
    final now = DateTime.now();
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    _history.insert(0, "User $username $action pada jam $time");

    // batasi 5 terbaru
    if (_history.length > 5) {
      _history.removeRange(5, _history.length);
    }
  }
}
