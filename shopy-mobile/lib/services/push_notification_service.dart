import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import 'device_token_api_service.dart';

/// Handler background message FCM — wajib top-level function (bukan method
/// instance), dipanggil Flutter di isolate terpisah saat notifikasi masuk
/// ketika app di background/terminated. FCM otomatis nampilin notifikasi
/// system tray dari payload `notification` yang dikirim backend, jadi handler
/// ini sengaja dibiarkan kosong untuk sekarang (belum ada kerjaan tambahan,
/// mis. simpan ke local cache, yang perlu jalan di background).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Setup Firebase Cloud Messaging: minta izin, ambil & daftarkan device token
/// ke backend, dan expose stream pesan foreground buat ditampilkan sebagai
/// banner in-app (lihat `widgets/notification/notification_banner_host.dart`).
///
/// Kalau Firebase belum dikonfigurasi asli (`firebase_options.dart` masih
/// placeholder — lihat file itu), [initialize] gagal dengan aman dan fitur
/// push otomatis nonaktif; sisa app tetap jalan normal.
class PushNotificationService {
  final DeviceTokenApiService _deviceTokenApiService;
  final _foregroundMessageController = StreamController<RemoteMessage>.broadcast();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  PushNotificationService(this._deviceTokenApiService);

  Stream<RemoteMessage> get onForegroundMessage => _foregroundMessageController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {
      // Belum di-setup (lihat catatan di TASKS.md Fase 6) — lewati diam-diam.
      return;
    }

    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _deviceTokenApiService.register(token);
    }
    _tokenRefreshSub = messaging.onTokenRefresh.listen(_deviceTokenApiService.register);

    FirebaseMessaging.onMessage.listen(_foregroundMessageController.add);
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageController.close();
  }
}
