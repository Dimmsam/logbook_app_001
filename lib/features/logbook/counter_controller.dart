import 'package:shared_preferences/shared_preferences.dart';

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
    } else if (action == 'mengurangi' && _counter < step) {
      _history.add(
        "Tidak dapat mengurangi, nilai counter kurang dari langkah!",
      );
    } else {
      _history.add(
        "User $action sebesar $_step pada jam ${time.hour}:${time.minute}",
      );
    }
    if (_history.length > 5) {
      _history.removeAt(0); // Hapus entri paling lama jika sudah 5
    }
  }

  Future<void> increment() async {
    _counter += _step;
    addHistory('menambahkan');
    await _saveData();
  }

  Future<void> decrement() async {
    if (_counter > 0 && _counter >= step) _counter -= _step;
    addHistory('mengurangi');
    await _saveData();
  }

  Future<void> reset() async {
    _counter = 0;
    addHistory('mereset');
    await _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_counter', _counter);
    await prefs.setStringList('history', _history);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt('last_counter') ?? 0;

    _history.clear();
    _history.addAll(prefs.getStringList('history') ?? []);
  }
}
