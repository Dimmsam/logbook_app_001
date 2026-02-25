import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/log_model.dart';

class LogController extends ChangeNotifier {
  final List<LogModel> _logs = [];
  static const String _storageKey = 'user_logs_data';

  List<LogModel> get logs => List.unmodifiable(_logs);

  LogController() {
    loadFromDisk();
  }

  void addLog(String title, String desc, String category) {
    _logs.add(
      LogModel(
        title: title,
        description: desc,
        timestamp: DateTime.now(),
        category: category,
      ),
    );
    notifyListeners();
    saveToDisk();
  }

  void updateLog(int index, String title, String desc, String category) {
    _logs[index] = LogModel(
      title: title,
      description: desc,
      timestamp: DateTime.now(),
      category: category,
    );
    notifyListeners();
    saveToDisk();
  }

  void removeLog(int index) {
    _logs.removeAt(index);
    notifyListeners();
    saveToDisk();
  }

  String encodeToJson(List<LogModel> logs) {
    final List<Map<String, dynamic>> mapList = logs
        .map((e) => e.toMap())
        .toList();
    return jsonEncode(mapList);
  }

  List<LogModel> decodeFromJson(String jsonString) {
    final List decoded = jsonDecode(jsonString);
    return decoded
        .map((e) => LogModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = encodeToJson(_logs);
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      _logs
        ..clear()
        ..addAll(decodeFromJson(data));
      notifyListeners();
    }
  }
}
