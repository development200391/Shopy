import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings/platform_settings.dart';
import '../services/admin_settings_api_service.dart';
import 'auth_provider.dart';

final adminSettingsApiServiceProvider = Provider<AdminSettingsApiService>((ref) {
  return AdminSettingsApiService(ref.watch(apiClientProvider));
});

final adminSettingsProvider = FutureProvider.autoDispose<PlatformSettings>((ref) {
  return ref.watch(adminSettingsApiServiceProvider).getSettings();
});
