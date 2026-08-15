import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ShopyAdminApp()));
}

class ShopyAdminApp extends StatelessWidget {
  const ShopyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopy Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Placeholder — diganti SplashScreen begitu Fase 1 (Auth & Shell) dikerjakan.
      home: const Scaffold(body: Center(child: Text('Shopy Admin'))),
    );
  }
}
