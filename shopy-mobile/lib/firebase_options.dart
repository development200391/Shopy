// File placeholder — GANTI dengan hasil generate `flutterfire configure`.
//
// Setelah kamu bikin project Firebase & jalanin `flutterfire configure` di
// folder `shopy-mobile`, file ini akan otomatis ditimpa dengan konfigurasi
// asli (apiKey/appId/projectId, dst per platform). Sebelum itu, isi di bawah
// cuma placeholder supaya project tetap bisa di-build — `Firebase.initializeApp()`
// akan gagal dengan aman (lihat `services/push_notification_service.dart`,
// kegagalan ini ditangkap supaya app tetap jalan tanpa fitur push).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform ini — jalankan `flutterfire configure`.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
  );

  static const android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
  );

  static const ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    iosBundleId: 'com.shopy.shopyMobile',
  );
}
