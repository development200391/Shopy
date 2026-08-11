import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum SocialProvider { google, facebook }

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback onPressed;

  const SocialLoginButton({super.key, required this.provider, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = provider == SocialProvider.google ? 'G' : 'f';
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.divider)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
