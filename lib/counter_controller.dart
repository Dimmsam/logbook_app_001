class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)

  int get value => _counter; // Getter untuk akses data

  int _step = 1; // Langkah default
  int get step => _step; // Getter untuk langkah
  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  } // Setter untuk nilai langkah baru

  final List<String> _history = []; // Riwayat perubahan counter
  List<String> get history => _history; // Getter untuk riwayat
  void addHistory(String action) {
    final time = DateTime.now();
    if (action == 'mereset') {
      _history.add("User $action pada jam ${time.hour}:${time.minute}");
    } else if (action == 'mengurangi' && _counter < step){
      _history.add("Tidak dapat mengurangi, nilai counter kurang dari langkah!",);
    } else {
      _history.add("User $action sebesar $_step pada jam ${time.hour}:${time.minute}");
    }
    if (_history.length >= 5) {
      _history.removeAt(0); // Hapus entri paling lama jika sudah 5
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
}
