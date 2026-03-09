import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/access_policy.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import './models/log_model.dart';

class LogController extends ChangeNotifier {
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final Box<LogModel> _pendingBox = Hive.box<LogModel>('pending_sync');
  static const String _storageKey = 'user_logs_data';

  final String userId;
  final String userRole;

  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<LogModel> get logs => List.unmodifiable(logsNotifier.value);

  LogController({this.userId = 'user_001', this.userRole = 'Anggota'}) {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _syncPending();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _syncPending() async {
    if (_pendingBox.isEmpty) return;
    await LogHelper.writeLog(
      'SYNC: Mencoba upload ${_pendingBox.length} entri yang tertunda...',
      source: 'log_controller.dart',
      level: 2,
    );
    final keys = _pendingBox.keys.toList();
    for (final key in keys) {
      final log = _pendingBox.get(key);
      if (log == null) continue;
      try {
        await MongoService().insertLog(log);
        await _pendingBox.delete(key);
        await LogHelper.writeLog(
          'SYNC: Berhasil upload "${log.title}" ke Cloud',
          source: 'log_controller.dart',
          level: 2,
        );
      } catch (_) {
        break;
      }
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId,
  ) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: authorId,
      teamId: teamId,
    );
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    notifyListeners();
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        'SUCCESS: Data tersinkron ke Cloud',
        source: 'log_controller.dart',
        level: 2,
      );
    } catch (e) {
      await _pendingBox.add(newLog);
      await LogHelper.writeLog(
        'WARNING: Data tersimpan lokal, akan sinkron saat online',
        source: 'log_controller.dart',
        level: 1,
      );
    }
  }

  void updateLog(int index, String title, String desc) {
    final current = logsNotifier.value;
    if (index < 0 || index >= current.length) return;
    final target = current[index];
    if (!AccessPolicy.canPerform(
      userRole,
      AccessPolicy.update,
      isOwner: target.authorId == userId,
    )) {
      LogHelper.writeLog(
        'SECURITY BREACH: Unauthorized update attempt',
        source: 'log_controller.dart',
        level: 1,
      );
      return;
    }
    final updated = LogModel(
      id: target.id,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: target.authorId,
      teamId: target.teamId,
    );
    final newList = [...logsNotifier.value];
    newList[index] = updated;
    logsNotifier.value = newList;
    notifyListeners();
    final boxKey = _myBox.keys.skip(index).first;
    _myBox.put(boxKey, updated);
  }

  void removeLog(int index) {
    final current = logsNotifier.value;
    if (index < 0 || index >= current.length) return;
    final target = current[index];
    if (!AccessPolicy.canPerform(
      userRole,
      AccessPolicy.delete,
      isOwner: target.authorId == userId,
    )) {
      LogHelper.writeLog(
        'SECURITY BREACH: Unauthorized delete attempt',
        source: 'log_controller.dart',
        level: 1,
      );
      return;
    }
    final newList = [...logsNotifier.value]..removeAt(index);
    logsNotifier.value = newList;
    notifyListeners();
    final boxKey = _myBox.keys.skip(index).first;
    _myBox.delete(boxKey);
  }

  Future<void> loadLogs(String teamId) async {
    logsNotifier.value = _myBox.values.toList();
    try {
      final cloudData = await MongoService().getLogs(teamId);
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = cloudData;
      await LogHelper.writeLog(
        'SYNC: Data berhasil diperbarui dari Atlas',
        source: 'log_controller.dart',
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'OFFLINE: Menggunakan data cache lokal',
        source: 'log_controller.dart',
        level: 2,
      );
    }
    notifyListeners();
  }
}
