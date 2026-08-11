import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store/store_summary.dart';
import '../providers/seller_provider.dart';
import '../screens/store/awaiting_verification_screen.dart';
import '../screens/store/open_store_screen.dart';
import '../screens/store/store_profile_screen.dart';

/// Dipanggil setelah login/register/buka-toko sukses (dan dari Splash) — satu-satunya
/// tempat yang memutuskan halaman berikutnya berdasarkan status toko dari server
/// (bukan dari claim JWT lokal), supaya logic routing tidak terduplikasi.
Future<void> navigateAfterAuth(BuildContext context, WidgetRef ref) async {
  final me = await ref.refresh(sellerMeProvider.future);
  if (!context.mounted) return;

  final store = me.store;
  final Widget next = store == null
      ? const OpenStoreScreen()
      : store.status == StoreStatus.active
      ? const StoreProfileScreen()
      : AwaitingVerificationScreen(store: store);

  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => next), (route) => false);
}
