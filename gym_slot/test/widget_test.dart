// Widget test dasar untuk GymSlot.
// Memverifikasi layar login tampil dan berisi tombol masuk Google.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_slot/main.dart';

void main() {
  testWidgets('Login screen shows Google sign-in button', (WidgetTester tester) async {
    await tester.pumpWidget(const GymSlotApp());

    // Logo GymSlot tampil.
    expect(find.text('GYMSLOT'), findsOneWidget);
    // Tombol masuk dengan Google tampil.
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });
}