import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_slot/core/network/api_client.dart';
import 'package:gym_slot/features/authentication/presentation/login_screen.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
import 'package:provider/provider.dart';

void main() {
  final apiClient = ApiClient('https://example.com');

  group('LoginScreen', () {
    testWidgets('displays login button and logo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
            ChangeNotifierProvider(create: (_) => GymProvider(apiClient)),
          ],
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.text('GYMSLOT'), findsOneWidget);
      expect(find.text('Booking slot gym.\nTanpa antre. Tanpa ribet.'), findsOneWidget);
    });

    testWidgets('button is tappable without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
            ChangeNotifierProvider(create: (_) => GymProvider(apiClient)),
          ],
          child: MaterialApp(home: const LoginScreen()),
        ),
      );

      // Tap the button - should not throw
      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pumpAndSettle();
    });
  });
}
