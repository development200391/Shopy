using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;

namespace shopy_api.Services;

/// <summary>
/// Kirim push notification lewat Firebase Cloud Messaging (Firebase Admin SDK).
/// Didaftarkan sebagai Singleton di DI supaya <see cref="FirebaseApp"/> cuma
/// dibuat sekali per proses. Kalau <c>Firebase:ServiceAccountKeyPath</c> belum
/// diisi/file-nya tidak ada, <see cref="IsConfigured"/> jadi false dan
/// <see cref="SendAsync"/> jadi no-op — pola yang sama seperti Google/Facebook
/// OAuth & Midtrans.
/// </summary>
public class PushNotificationService : IPushNotificationService
{
    private readonly FirebaseApp? _app;
    private readonly ILogger<PushNotificationService> _logger;

    public PushNotificationService(IConfiguration configuration, ILogger<PushNotificationService> logger)
    {
        _logger = logger;

        var keyPath = configuration["Firebase:ServiceAccountKeyPath"];
        if (string.IsNullOrEmpty(keyPath) || !File.Exists(keyPath))
        {
            _app = null;
            return;
        }

        // GoogleCredential.FromFile jadi obsolete di versi Google.Apis.Auth terbaru
        // (diarahkan ke CredentialFactory yang berbasis async) — dipertahankan di sini
        // karena dipanggil sinkron sekali saat startup, bukan di request path.
#pragma warning disable CS0618
        _app = FirebaseApp.DefaultInstance ?? FirebaseApp.Create(new AppOptions
        {
            Credential = GoogleCredential.FromFile(keyPath),
        });
#pragma warning restore CS0618
    }

    public bool IsConfigured => _app is not null;

    public async Task SendAsync(IReadOnlyList<string> tokens, string title, string body, IReadOnlyDictionary<string, string>? data = null)
    {
        if (_app is null || tokens.Count == 0)
        {
            return;
        }

        var messaging = FirebaseMessaging.GetMessaging(_app);
        var message = new MulticastMessage
        {
            Fids = tokens,
            Notification = new Notification { Title = title, Body = body },
            Data = data,
        };

        try
        {
            await messaging.SendEachForMulticastAsync(message);
        }
        catch (Exception ex)
        {
            // Gagal kirim push tidak boleh menggagalkan alur bisnis utama (mis. update
            // status pesanan) — notifikasi in-app di database tetap tersimpan.
            _logger.LogError(ex, "Gagal mengirim push notification ke {Count} device.", tokens.Count);
        }
    }
}
