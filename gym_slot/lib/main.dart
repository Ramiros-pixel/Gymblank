import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/presentation/login_screen.dart';

void main() {
  runApp(const GymSlotApp());
}

class GymSlotApp extends StatelessWidget {
  const GymSlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymSlot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}