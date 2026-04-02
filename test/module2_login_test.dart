// test/module2_login_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller_modul2.dart';

void main() {
  var actual, expected;

  group('Module 2 - LoginController (Authentication)', () {
    late LoginController controller;

    setUp(() {
      // fresh instance tiap test case — reset semua state
      controller = LoginController();
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 1: EMPTY FIELD VALIDATION
    // ═══════════════════════════════════════════════════════

    // TC01 ──────────────────────────────────────────────────
    test('TC01: login returns emptyField when both fields empty', () {
      // (1) Arrange
      // controller sudah fresh dari setUp()

      // (2) Act
      actual   = controller.login('', '');
      expected = LoginResult.emptyField;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC02 ──────────────────────────────────────────────────
    test('TC02: login returns emptyField when username is empty', () {
      actual   = controller.login('', 'password1');
      expected = LoginResult.emptyField;
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC03 ──────────────────────────────────────────────────
    test('TC03: login returns emptyField when password is empty', () {
      actual   = controller.login('user1', '');
      expected = LoginResult.emptyField;
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 2: VALID & INVALID CREDENTIALS
    // ═══════════════════════════════════════════════════════

    // TC04 ──────────────────────────────────────────────────
    test('TC04: login returns success with valid credentials', () {
      actual   = controller.login('user1', 'password1');
      expected = LoginResult.success;
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC05 ──────────────────────────────────────────────────
    test('TC05: login returns wrongCredential — username not registered', () {
      actual   = controller.login('userXYZ', 'password1');
      expected = LoginResult.wrongCredential;
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC06 ──────────────────────────────────────────────────
    test('TC06: login returns wrongCredential — password wrong', () {
      actual   = controller.login('user1', 'wrongpass');
      expected = LoginResult.wrongCredential;
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // ═══════════════════════════════════════════════════════
    // FLOW 3: LOCKOUT MECHANISM
    // ═══════════════════════════════════════════════════════

    // TC07 ──────────────────────────────────────────────────
    test('TC07: login returns locked after 3 consecutive failed attempts', () {
      // (1) Arrange: controller fresh

      // (2) Act: gagal 3x
      controller.login('user1', 'wrongpass'); // attempt 1
      controller.login('user1', 'wrongpass'); // attempt 2
      actual   = controller.login('user1', 'wrongpass'); // attempt 3 → locked
      expected = LoginResult.locked;

      // (3) Assert: return value + state isLocked
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
      expect(controller.isLocked, true,
        reason: 'isLocked should be true after 3 failed attempts');
    });

    // TC08 ──────────────────────────────────────────────────
    test('TC08: login returns locked when account is still locked', () {
      // (1) Arrange: simulasi akun sudah terkunci
      controller.isLocked   = true;
      controller.lockEndTime = DateTime.now().add(const Duration(seconds: 10));

      // (2) Act: coba login meski credentials benar
      actual   = controller.login('user1', 'password1');
      expected = LoginResult.locked;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

    // TC09 ──────────────────────────────────────────────────
    test('TC09: getRemainingSeconds returns 0 when not locked', () {
      // (1) Arrange: controller fresh, isLocked = false

      // (2) Act
      actual   = controller.getRemainingSeconds();
      expected = 0;

      // (3) Assert
      expect(actual, expected,
        reason: 'Expected $expected but got $actual');
    });

  }); // end group
}
