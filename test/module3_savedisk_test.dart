// test/module3_savedisk_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/log_controller_modul3.dart';
import 'package:logbook_app_001/features/logbook/models/log_model_modul3.dart';

void main() {
  Object? actual;
  Object? expected;

  group('Module 3 - LogController (Save Data to Disk)', () {
    setUp(() async {
      // Wajib: reset mock storage sebelum setiap test
      SharedPreferences.setMockInitialValues({});
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 1: SAVE & LOAD PERSISTENCE
    // ═══════════════════════════════════════════════════════

    // TC01 ──────────────────────────────────────────────────
    test('TC01: log data should persist after save and reload', () async {
      // (1) Arrange
      final ctrl1 = LogController();
      await Future.delayed(Duration.zero); // tunggu loadFromDisk()

      // (2) Act: tambah log, lalu load di instance baru
      ctrl1.addLog('Judul Test', 'Deskripsi', 'Software');
      await ctrl1.saveToDisk();

      final ctrl2 = LogController();
      await Future.delayed(Duration.zero); // tunggu loadFromDisk() ctrl2

      actual = ctrl2.logs.length;
      expected = 1;

      // (3) Assert
      expect(actual, expected, reason: 'Expected $expected but got $actual');
      expect(
        ctrl2.logs[0].title,
        'Judul Test',
        reason: 'Title tidak sesuai setelah reload',
      );
    });

    // TC02 ──────────────────────────────────────────────────
    test(
      'TC02: deleted log should not persist after save and reload',
      () async {
        // (1) Arrange: tambah 2 log, simpan
        final ctrl1 = LogController();
        await Future.delayed(Duration.zero);
        ctrl1.addLog('Log Pertama', 'Desc 1', 'Software');
        ctrl1.addLog('Log Kedua', 'Desc 2', 'Software');
        await ctrl1.saveToDisk();

        // (2) Act: hapus log pertama, simpan, reload
        ctrl1.removeLog(0);
        await ctrl1.saveToDisk();

        final ctrl2 = LogController();
        await Future.delayed(Duration.zero);

        actual = ctrl2.logs.length;
        expected = 1;

        // (3) Assert
        expect(actual, expected, reason: 'Expected $expected but got $actual');
      },
    );

    // TC03 ──────────────────────────────────────────────────
    test(
      'TC03: loadFromDisk should keep logs empty when storage is empty',
      () async {
        // (1) Arrange: SharedPreferences sudah kosong dari setUp()

        // (2) Act
        final ctrl = LogController();
        await Future.delayed(Duration.zero); // tunggu loadFromDisk()

        actual = ctrl.logs.length;
        expected = 0;

        // (3) Assert
        expect(actual, expected, reason: 'Expected $expected but got $actual');
      },
    );

    // ═══════════════════════════════════════════════════════
    // FLOW 2: JSON ENCODE / DECODE
    // ═══════════════════════════════════════════════════════

    // TC04 ──────────────────────────────────────────────────
    test(
      'TC04: encodeToJson should return valid JSON string with title key',
      () async {
        // (1) Arrange
        final ctrl = LogController();
        await Future.delayed(Duration.zero);
        final logModel = LogModel(
          title: 'Judul Test',
          description: 'Deskripsi',
          timestamp: DateTime(2025, 1, 1),
          category: 'Software',
        );

        // (2) Act
        final result = ctrl.encodeToJson([logModel]);

        // (3) Assert
        expect(result, isA<String>(), reason: 'Hasil harus berupa String');
        expect(
          result.contains('title'),
          true,
          reason: 'JSON harus mengandung key title',
        );
      },
    );

    // TC05 ──────────────────────────────────────────────────
    test('TC05: decodeFromJson should return correct LogModel list', () async {
      // (1) Arrange
      final ctrl = LogController();
      await Future.delayed(Duration.zero);
      const jsonString =
          '[{"title":"Judul Test","description":"Deskripsi","timestamp":"2025-01-01T00:00:00.000","category":"Software"}]';

      // (2) Act
      final result = ctrl.decodeFromJson(jsonString);

      // (3) Assert
      actual = result.length;
      expected = 1;
      expect(
        actual,
        expected,
        reason: 'Expected $expected items but got $actual',
      );
      expect(result[0].title, 'Judul Test', reason: 'Title tidak sesuai');
    });

    // TC06 ──────────────────────────────────────────────────
    test(
      'TC06: encode-decode round-trip should produce identical data',
      () async {
        // (1) Arrange
        final ctrl = LogController();
        await Future.delayed(Duration.zero);
        final original = [
          LogModel(
            title: 'Judul Test',
            description: 'Deskripsi',
            timestamp: DateTime(2025, 1, 1),
            category: 'Software',
          ),
        ];

        // (2) Act: encode → decode
        final jsonStr = ctrl.encodeToJson(original);
        final result = ctrl.decodeFromJson(jsonStr);

        actual = result[0].title;
        expected = 'Judul Test';

        // (3) Assert
        expect(actual, expected, reason: 'Expected $expected but got $actual');
      },
    );

    // ═══════════════════════════════════════════════════════
    // FLOW 3: CRUD OPERATIONS
    // ═══════════════════════════════════════════════════════

    // TC07 ──────────────────────────────────────────────────
    test('TC07: addLog should increase logs length by 1', () async {
      // (1) Arrange
      final ctrl = LogController();
      await Future.delayed(Duration.zero);
      // logs.length awal = 0

      // (2) Act
      ctrl.addLog('Judul', 'Desc', 'Software');

      actual = ctrl.logs.length;
      expected = 1;

      // (3) Assert
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC08 ──────────────────────────────────────────────────
    test('TC08: updateLog should change log data at given index', () async {
      // (1) Arrange
      final ctrl = LogController();
      await Future.delayed(Duration.zero);
      ctrl.addLog('Judul Lama', 'Desc Lama', 'Software');

      // (2) Act
      ctrl.updateLog(0, 'Judul Baru', 'Desc Baru', 'Hardware');

      actual = ctrl.logs[0].title;
      expected = 'Judul Baru';

      // (3) Assert
      expect(actual, expected, reason: 'Expected $expected but got $actual');
      expect(
        ctrl.logs[0].category,
        'Hardware',
        reason: 'Category harus berubah menjadi Hardware',
      );
    });

    // TC09 ──────────────────────────────────────────────────
    test('TC09: removeLog should decrease logs length by 1', () async {
      // (1) Arrange
      final ctrl = LogController();
      await Future.delayed(Duration.zero);
      ctrl.addLog('Log 1', 'Desc 1', 'Software');
      ctrl.addLog('Log 2', 'Desc 2', 'Software');
      // logs.length = 2

      // (2) Act
      ctrl.removeLog(0);

      actual = ctrl.logs.length;
      expected = 1;

      // (3) Assert
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });
  }); // end group
}
