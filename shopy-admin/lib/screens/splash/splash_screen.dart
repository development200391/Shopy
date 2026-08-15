import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../../routing/post_auth_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../auth/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    await Future.wait([
      ref.read(authProvider.notifier).bootstrap(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;

    final status = ref.read(authProvider).status;
    if (status != AuthStatus.authenticated) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    await navigateAfterAuth(context, ref);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _PulseRing(progress: _pulseController.value),
                      _PulseRing(progress: (_pulseController.value + 0.5) % 1.0),
                      child!,
                    ],
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: SvgPicture.asset('assets/logo.svg'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Shopy Admin',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Verifikasi & kelola platform Shopy', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: AppColors.secondary),
                const SizedBox(width: 6),
                _Dot(color: AppColors.secondary.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                _Dot(color: AppColors.secondary.withValues(alpha: 0.25)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double progress;

  const _PulseRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = 96 + progress * 124;
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
