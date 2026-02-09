class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)

  int get value => _counter; // Getter untuk akses data

  final int _step = 1; // Langkah default
  int get step => _step; // Getter untuk langkah

  void increment() => _counter += step;
  void decrement() { if (_counter > 0) _counter -= step; }
  void reset() => _counter = 0;
}
