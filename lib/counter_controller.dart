class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = []; // private history

  int get value => _counter;
  int get step => _step;

  List<String> get history => List.unmodifiable(_history);

  void setStep(int newStep) {
    if (newStep < 1) return;
    _step = newStep;
    _addHistory("Step diubah menjadi $_step");
  }

  void increment() {
    _counter += _step;
    _addHistory("+$_step (total: $_counter)");
  }

void decrement() {
  if (_counter == 0) {
    _addHistory("Gagal decrement (counter sudah 0)");
    return;
  }

  final before = _counter;
  _counter -= _step;
  if (_counter < 0) _counter = 0;

  final actual = before - _counter;
  _addHistory("-$actual (total: $_counter)");
}

  void reset() {
    _counter = 0;
    _addHistory("Reset (total: $_counter)");
  }

  void _addHistory(String action) {
    final now = DateTime.now();
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // masukin terbaru di atas
    _history.insert(0, "[$time] $action");

    // batasi cuma 5 data terbaru
    if (_history.length > 5) {
      _history.removeRange(5, _history.length);
    }
  }
}
