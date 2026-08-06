import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ShopyApp());
}

class ShopyApp extends StatelessWidget {
  const ShopyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ShopyHomePage(),
    );
  }
}

class ShopyHomePage extends StatelessWidget {
  const ShopyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/logo.svg', width: 96, height: 96),
              const SizedBox(height: AppSpacing.lg),
              Text('Shopy', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Belanja jadi lebih mudah',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: () {}, child: const Text('Mulai')),
            ],
          ),
        ),
      ),
    );
  }
}
