import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: ShopySellerApp()));
}

class ShopySellerApp extends StatelessWidget {
  const ShopySellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopy Seller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Placeholder — diganti SplashScreen begitu Fase 1 (TASKSELLER.md) dikerjakan.
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/logo.svg', width: 96, height: 96),
            const SizedBox(height: 16),
            Text('Shopy Seller', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
