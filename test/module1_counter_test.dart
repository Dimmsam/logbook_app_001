// test/module1_counter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/logbook/counter_controller_modul1.dart';

void main() {
  var actual, expected;

  group('Module 1 - CounterController', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController(); // fresh instance tiap test
    });

    // TC01 ─────────────────────────────────────────────────────
    test('initial value should be 0', () {
      actual   = controller.value;
      expected = 0;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC02 ─────────────────────────────────────────────────────
    test('setStep should change step value', () {
      controller.setStep(5);
      actual   = controller.step;
      expected = 5;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC03 ─────────────────────────────────────────────────────
    test('setStep should ignore negative value', () {
      controller.setStep(3);
      controller.setStep(-1);
      actual   = controller.step;
      expected = 3;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC04 ─────────────────────────────────────────────────────
    test('increment should increase counter by default step', () {
      controller.increment();
      actual   = controller.value;
      expected = 1;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC05 ─────────────────────────────────────────────────────
    test('increment should increase counter based on custom step', () {
      controller.setStep(3);
      controller.increment();
      actual   = controller.value;
      expected = 3;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC06 ─────────────────────────────────────────────────────
    test('decrement should not go below zero', () {
      controller.setStep(5);
      controller.decrement(); // counter=0, step=5 -> tidak bergerak
      actual   = controller.value;
      expected = 0;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC07 ─────────────────────────────────────────────────────
    test('decrement should decrease counter when counter >= step', () {
      controller.setStep(2);
      controller.increment(); // counter = 2
      controller.increment(); // counter = 4
      controller.decrement(); // counter = 2
      actual   = controller.value;
      expected = 2;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC08 ─────────────────────────────────────────────────────
    test('reset should set counter back to zero', () {
      controller.setStep(3);
      controller.increment(); // counter = 3
      controller.reset();
      actual   = controller.value;
      expected = 0;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC09 ─────────────────────────────────────────────────────
    test('history should not exceed 5 entries', () {
      for (int i = 0; i < 6; i++) {
        controller.increment();
      }
      actual   = controller.history.length;
      expected = 5;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

    // TC10 ─────────────────────────────────────────────────────
    test('setStep should ignore zero value', () {
      controller.setStep(3);
      controller.setStep(0);
      actual   = controller.step;
      expected = 3;
      expect(actual, expected,
             reason: 'Expected $expected but got $actual');
    });

  }); // end group
}
