namespace shopy_api.Models.Orders;

public record CourierOption(string Code, string Service, string Label, decimal Price, string Eta);

/// <summary>
/// Tabel tarif kurir statis (TASKSELLER.md Fase 4: "minimal tabel tarif statis dulu,
/// integrasi API kurir menyusul") — dipakai backend buat quote ongkir default per toko
/// saat checkout. Bukan per-berat; sengaja sederhana dulu.
/// </summary>
public static class Couriers
{
    public static readonly IReadOnlyList<CourierOption> Options =
    [
        new("JNE", "REG", "JNE Reguler", 15000m, "2-3 hari"),
        new("JNT", "EZ", "J&T Express", 14000m, "2-4 hari"),
        new("SICEPAT", "REG", "SiCepat REG", 16000m, "1-3 hari"),
    ];

    public static CourierOption Default => Options[0];
}
