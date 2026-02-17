import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  // Helper bikin key berdasarkan username
  String _counterKey(String username) => 'last_counter_$username';
  String _stepKey(String username) => 'last_step_$username';
  String _historyKey(String username) => 'history_list_$username';

  // ==============================
  // LOAD & SAVE PER USER
  // ==============================

  Future<void> loadAll(String username) async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt(_counterKey(username)) ?? 0;
    _step = prefs.getInt(_stepKey(username)) ?? 1;

    final savedHistory = prefs.getStringList(_historyKey(username)) ?? [];
    _history
      ..clear()
      ..addAll(savedHistory);
  }

  Future<void> saveAll(String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_counterKey(username), _counter);
    await prefs.setInt(_stepKey(username), _step);
    await prefs.setStringList(_historyKey(username), _history);
  }

  // kalau mau hapus data khusus user
  Future<void> clearUserData(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_counterKey(username));
    await prefs.remove(_stepKey(username));
    await prefs.remove(_historyKey(username));
  }

  // ==============================
  // LOGIC + HISTORY (SRP)
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

    if (_history.length > 5) {
      _history.removeRange(5, _history.length);
    }
  }
}
