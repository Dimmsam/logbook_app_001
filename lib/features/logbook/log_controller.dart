import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import './models/log_model.dart';

class LogController extends ChangeNotifier {
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');
  final Box<LogModel> _pendingBox = Hive.box<LogModel>('pending_sync');

  final String userId;
  final String userRole;

  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  late final ValueNotifier<Set<String>> pendingIdsNotifier;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<LogModel> get logs => List.unmodifiable(logsNotifier.value);

  LogController({this.userId = 'user_001', this.userRole = 'Anggota'}) {
    // Inisialisasi dari pending box yang tersisa (misal setelah app restart)
    pendingIdsNotifier = ValueNotifier({
      ..._pendingBox.values.where((l) => l.id != null).map((l) => l.id!),
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) _syncPending();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    logsNotifier.dispose();
    pendingIdsNotifier.dispose();
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
        // Hapus dari notifier agar ikon cloud berubah ke hijau
        pendingIdsNotifier.value = {...pendingIdsNotifier.value}
          ..remove(log.id);
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
    String teamId, {
    bool isPublic = false,
    String category = 'Software',
  }) async {
    final newLog = LogModel(
      id: ObjectId().oid,
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic,
      category: category,
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
      // Tandai sebagai pending agar ikon cloud menampilkan status orange
      pendingIdsNotifier.value = {...pendingIdsNotifier.value, newLog.id!};
      await LogHelper.writeLog(
        'WARNING: Data tersimpan lokal, akan sinkron saat online',
        source: 'log_controller.dart',
        level: 1,
      );
    }
  }

  /// Kedaulatan penuh: hanya pemilik (authorId == userId) yang bisa mengedit.
  Future<void> updateLog(
    String logId,
    String title,
    String desc,
    bool isPublic,
    String category,
  ) async {
    final current = logsNotifier.value;
    final targetIndex = current.indexWhere((l) => l.id == logId);
    if (targetIndex == -1) return;
    final target = current[targetIndex];

    // Owner-only: role Ketua sekalipun tidak berhak edit milik orang lain
    if (target.authorId != userId) {
      LogHelper.writeLog(
        'SECURITY BREACH: Unauthorized update attempt by $userId on log $logId',
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
      isPublic: isPublic,
      category: category,
    );

    final newList = [...logsNotifier.value];
    newList[targetIndex] = updated;
    logsNotifier.value = newList;
    notifyListeners();

    // Update Hive (cari key berdasarkan ID, bukan index posisi)
    final boxKey = _myBox.keys.firstWhere(
      (k) => _myBox.get(k)?.id == logId,
      orElse: () => null,
    );
    if (boxKey != null) _myBox.put(boxKey, updated);

    // Sinkron ke MongoDB (best-effort)
    try {
      await MongoService().updateLog(updated);
    } catch (_) {
      // Data sudah aman di Hive, sync cloud tidak kritikal
    }
  }

  /// Kedaulatan penuh: hanya pemilik (authorId == userId) yang bisa menghapus.
  Future<void> removeLog(String logId) async {
    final current = logsNotifier.value;
    final targetIndex = current.indexWhere((l) => l.id == logId);
    if (targetIndex == -1) return;
    final target = current[targetIndex];

    // Owner-only
    if (target.authorId != userId) {
      LogHelper.writeLog(
        'SECURITY BREACH: Unauthorized delete attempt by $userId on log $logId',
        source: 'log_controller.dart',
        level: 1,
      );
      return;
    }

    final newList = [...logsNotifier.value]..removeAt(targetIndex);
    logsNotifier.value = newList;
    notifyListeners();

    // Hapus dari Hive
    final boxKey = _myBox.keys.firstWhere(
      (k) => _myBox.get(k)?.id == logId,
      orElse: () => null,
    );
    if (boxKey != null) _myBox.delete(boxKey);

    // Hapus dari MongoDB (best-effort)
    try {
      if (target.id != null) await MongoService().deleteLog(target.id!);
    } catch (_) {}
  }

  Future<void> loadLogs(String teamId) async {
    logsNotifier.value = _myBox.values.toList();
    try {
      final cloudData = await MongoService().getLogs(teamId);
      // Gabungkan data cloud dengan pending yang belum ter-upload
      // agar log offline tidak menghilang dari UI
      final cloudIds = cloudData.map((l) => l.id).toSet();
      final pendingOnly = _pendingBox.values
          .where((l) => !cloudIds.contains(l.id))
          .toList();
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = [...cloudData, ...pendingOnly];
      // Perbarui pendingIds berdasarkan _pendingBox terkini
      pendingIdsNotifier.value = {
        ..._pendingBox.values.where((l) => l.id != null).map((l) => l.id!),
      };
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
