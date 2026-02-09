class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)

  int get value => _counter; // Getter untuk akses data

  int _step = 1; // Langkah default

  int get step => _step; // Getter untuk langkah

  final List<String> _history = []; // Riwayat perubahan counter

  List<String> get history => _history; // Getter untuk riwayat

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  }

  void increment() {
    _counter += _step;
    addHistory('menambahkan');
  }

  void decrement() {
    if (_counter > 0 && _counter >= step) _counter -= _step;
    addHistory('mengurangi');
  }

  void reset() {
    _counter = 0;
    addHistory('mereset');
  }

  void addHistory(String action) {
    final now = DateTime.now();
    final time = "${now.hour.toString()}:${now.minute.toString()}";

    if (action == 'mereset') {
      _history.add("User $action pada jam $time");
    } else if (action == 'mengurangi' && _counter < step){
      _history.add("Tidak dapat mengurangi, nilai counter kurang dari langkah pada jam $time",);
    } else {
      _history.add("User $action sebesar $_step pada jam $time");
    }

    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }
}
