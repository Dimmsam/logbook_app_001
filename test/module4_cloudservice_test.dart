// test/module4_cloudservice_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_001/features/logbook/models/log_model_modul4.dart';

// ── FakeMongoService: pengganti MongoService asli ──────────
// Menggunakan List<LogModel> sebagai in-memory storage.
// Tidak butuh koneksi jaringan sama sekali.
class FakeMongoService {
  final List<LogModel> _store = [];

  Future<List<LogModel>> getLogs() async => List.unmodifiable(_store);

  Future<void> insertLog(LogModel log) async => _store.add(log);

  Future<void> deleteLog(ObjectId id) async =>
    _store.removeWhere((l) => l.id == id);

  Future<void> updateLog(LogModel log) async {
    if (log.id == null) {
      throw Exception('ID Log tidak ditemukan untuk update');
    }
    final idx = _store.indexWhere((l) => l.id == log.id);
    if (idx != -1) _store[idx] = log;
  }
}

// ── Helper: buat LogModel dengan id baru ───────────────────
LogModel makeLog({
  required String title,
  String desc = 'Deskripsi',
  String category = 'Software',
  ObjectId? id,
}) => LogModel(
  id:          id ?? ObjectId(),
  title:       title,
  description: desc,
  timestamp:   DateTime(2025, 1, 1),
  category:    category,
);

// ═══════════════════════════════════════════════════════════
void main() {
  var actual, expected;

  group('Module 4 - Cloud Service (LogModel + FakeMongoService)', () {

    // ═══════════════════════════════════════════════════════
    // FLOW 1: LogModel SERIALISASI (toMap / fromMap)
    // ═══════════════════════════════════════════════════════

    // TC01 ──────────────────────────────────────────────────
    test('TC01: toMap should return Map with all required keys', () {
      // (1) Arrange
      final log = makeLog(title: 'Test Log');

      // (2) Act
      final result = log.toMap();

      // (3) Assert
      expect(result, isA<Map<String, dynamic>>(),
        reason: 'Hasil harus berupa Map');
      expect(result.containsKey('_id'), true,
        reason: 'Map harus punya key _id');
      expect(result.containsKey('title'), true,
        reason: 'Map harus punya key title');
      expect(result['title'], 'Test Log',
        reason: 'Nilai title harus sesuai');
    });

    // TC02 ──────────────────────────────────────────────────
    test('TC02: fromMap should create LogModel with correct field values', () {
      // (1) Arrange
      final map = {
        '_id':         ObjectId(),
        'title':       'Test Log',
        'description': 'Deskripsi',
        'timestamp':   '2025-01-01T00:00:00.000',
        'category':    'Software',
      };

      // (2) Act
      final result = LogModel.fromMap(map);

      // (3) Assert
      actual   = result.title;
      expected = 'Test Log';
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
      expect(result.category, 'Software',
        reason: 'Category harus Software');
    });

    // TC03 ──────────────────────────────────────────────────
    test('TC03: toMap then fromMap round-trip should produce identical data', () {
      // (1) Arrange
      final original = makeLog(title: 'Test Log');

      // (2) Act: round-trip
      final map      = original.toMap();
      final restored = LogModel.fromMap(map);

      actual   = restored.title;
      expected = 'Test Log';

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
      expect(restored.category, original.category,
        reason: 'Category harus identik setelah round-trip');
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 2: CRUD VIA FakeMongoService
    // ═══════════════════════════════════════════════════════

    // TC04 ──────────────────────────────────────────────────
    test('TC04: insertLog then getLogs should return list with 1 item', () async {
      // (1) Arrange
      final fake = FakeMongoService();
      final log  = makeLog(title: 'Test Log');

      // (2) Act
      await fake.insertLog(log);
      final result = await fake.getLogs();

      actual   = result.length;
      expected = 1;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
      expect(result[0].title, 'Test Log',
        reason: 'Title harus sesuai');
    });

    // TC05 ──────────────────────────────────────────────────
    test('TC05: deleteLog then getLogs should return empty list', () async {
      // (1) Arrange
      final fake = FakeMongoService();
      final log  = makeLog(title: 'Test Log');
      await fake.insertLog(log);

      // (2) Act
      await fake.deleteLog(log.id!);
      final result = await fake.getLogs();

      actual   = result.length;
      expected = 0;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC06 ──────────────────────────────────────────────────
    test('TC06: inserting two logs should make getLogs return length 2', () async {
      // (1) Arrange
      final fake = FakeMongoService();

      // (2) Act
      await fake.insertLog(makeLog(title: 'Log Pertama'));
      await fake.insertLog(makeLog(title: 'Log Kedua'));
      final result = await fake.getLogs();

      actual   = result.length;
      expected = 2;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 3: updateLog & EDGE CASES
    // ═══════════════════════════════════════════════════════

    // TC07 ──────────────────────────────────────────────────
    test('TC07: updateLog should replace log data with matching id', () async {
      // (1) Arrange
      final fake  = FakeMongoService();
      final id    = ObjectId();
      final logLama = makeLog(title: 'Judul Lama', id: id);
      await fake.insertLog(logLama);

      // (2) Act
      final logBaru = makeLog(title: 'Judul Baru', id: id);
      await fake.updateLog(logBaru);
      final result = await fake.getLogs();

      actual   = result[0].title;
      expected = 'Judul Baru';

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC08 ──────────────────────────────────────────────────
    test('TC08: updateLog should throw Exception when log id is null', () async {
      // (1) Arrange
      final fake       = FakeMongoService();
      final logTanpaId = LogModel(
        id:          null,   // ← tidak ada id
        title:       'Test',
        description: 'Desc',
        timestamp:   DateTime(2025, 1, 1),
      );

      // (2) Act + Assert: expect throws
      expect(
        () async => await fake.updateLog(logTanpaId),
        throwsException,
        reason: 'Harus throw Exception jika id null',
      );
    });

    // TC09 ──────────────────────────────────────────────────
    test('TC09: getLogs should return empty list when storage is empty', () async {
      // (1) Arrange
      final fake = FakeMongoService(); // fresh, belum ada insert

      // (2) Act
      final result = await fake.getLogs();

      actual   = result.length;
      expected = 0;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

  }); // end group
}
