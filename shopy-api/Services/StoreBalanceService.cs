using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public interface IStoreBalanceService
{
    Task AddPendingAsync(SubOrder subOrder);
    Task SettleAsync(SubOrder subOrder);
    Task ReleasePendingAsync(SubOrder subOrder);
}

/// <summary>
/// Mengelola saldo toko (<see cref="StoreBalance"/>) &amp; buku besar mutasi (<see cref="BalanceTransaction"/>).
/// <see cref="StoreBalance.PendingBalance"/> bukan bagian ledger — cuma penanda "dana ditahan dari
/// pesanan berjalan", dilepas balik (tanpa baris ledger) kalau pesanan gagal setelah dibayar
/// (<see cref="ReleasePendingAsync"/>), atau dipindah ke <see cref="StoreBalance.AvailableBalance"/>
/// (dengan 2 baris ledger: SaleIncome + Commission) begitu pesanan selesai (<see cref="SettleAsync"/>).
/// </summary>
public class StoreBalanceService(ShopyDbContext dbContext) : IStoreBalanceService
{
    public async Task AddPendingAsync(SubOrder subOrder)
    {
        var balance = await GetOrCreateBalanceAsync(subOrder.StoreId);
        balance.PendingBalance += subOrder.SellerEarning;
        balance.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
    }

    public async Task ReleasePendingAsync(SubOrder subOrder)
    {
        var balance = await GetOrCreateBalanceAsync(subOrder.StoreId);
        balance.PendingBalance -= subOrder.SellerEarning;
        balance.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
    }

    public async Task SettleAsync(SubOrder subOrder)
    {
        var balance = await GetOrCreateBalanceAsync(subOrder.StoreId);
        var now = DateTime.UtcNow;

        balance.PendingBalance -= subOrder.SellerEarning;

        // VoucherDiscount ditanggung seller (bukan Shopy) — dilipat ke baris SaleIncome, bukan
        // baris ledger terpisah, karena secara efektif itu mengurangi nilai jual dari sononya.
        // Commission tetap dihitung dari Subtotal asli (dihitung saat checkout), tidak ikut berkurang.
        var grossIncome = subOrder.Subtotal - subOrder.VoucherDiscount + subOrder.ShippingCost;
        balance.AvailableBalance += grossIncome;
        dbContext.BalanceTransactions.Add(new BalanceTransaction
        {
            Id = Guid.NewGuid(),
            StoreId = subOrder.StoreId,
            Type = BalanceTransactionType.SaleIncome,
            Amount = grossIncome,
            BalanceAfter = balance.AvailableBalance,
            SubOrderId = subOrder.Id,
            Description = $"Pesanan #{subOrder.SubOrderNumber}",
            CreatedAt = now,
        });

        balance.AvailableBalance -= subOrder.CommissionAmount;
        dbContext.BalanceTransactions.Add(new BalanceTransaction
        {
            Id = Guid.NewGuid(),
            StoreId = subOrder.StoreId,
            Type = BalanceTransactionType.Commission,
            Amount = -subOrder.CommissionAmount,
            BalanceAfter = balance.AvailableBalance,
            SubOrderId = subOrder.Id,
            Description = $"Komisi pesanan #{subOrder.SubOrderNumber}",
            CreatedAt = now,
        });

        balance.TotalEarning += subOrder.SellerEarning;
        balance.UpdatedAt = now;

        await dbContext.SaveChangesAsync();
    }

    private async Task<StoreBalance> GetOrCreateBalanceAsync(Guid storeId)
    {
        var balance = await dbContext.StoreBalances.SingleOrDefaultAsync(b => b.StoreId == storeId);
        if (balance is not null)
        {
            return balance;
        }

        balance = new StoreBalance { StoreId = storeId, UpdatedAt = DateTime.UtcNow };
        dbContext.StoreBalances.Add(balance);
        return balance;
    }
}
