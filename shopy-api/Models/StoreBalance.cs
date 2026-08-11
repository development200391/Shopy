namespace shopy_api.Models;

/// <summary>
/// Satu baris ringkasan saldo per toko (bukan tabel transaksional — lihat <see cref="BalanceTransaction"/>
/// untuk mutasinya). <see cref="StoreId"/> sekaligus jadi primary key (relasi 1:1 dengan <see cref="Store"/>).
/// </summary>
public class StoreBalance
{
    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public decimal AvailableBalance { get; set; }
    public decimal PendingBalance { get; set; }
    public decimal TotalEarning { get; set; }

    public DateTime UpdatedAt { get; set; }
}
