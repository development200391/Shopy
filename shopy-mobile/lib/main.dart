import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/notification/notification_banner_host.dart';

void main() {
  runApp(const ProviderScope(child: ShopyApp()));
}

class ShopyApp extends StatelessWidget {
  const ShopyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) => NotificationBannerHost(child: child!),
    );
  }
}
