namespace shopy_api.Models;

/// <summary>
/// Metode pembayaran yang benar-benar didukung lewat integrasi Midtrans Core API
/// di app ini. Mockup (07_pembayaran_pilih_metode.png) juga menampilkan Transfer
/// Mandiri, OVO, dan DANA — sengaja tidak diimplementasikan karena butuh
/// endpoint/alur Midtrans yang berbeda (Mandiri pakai "echannel" bukan
/// "bank_transfer", OVO butuh linking nomor HP, DANA tidak tersedia langsung
/// di Core API) dan di luar scope saat ini.
/// </summary>
public enum PaymentMethod
{
    BcaVa,
    BniVa,
    GoPay,
    Qris,
}
