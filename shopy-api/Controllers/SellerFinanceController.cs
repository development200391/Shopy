using System.Globalization;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Catalog;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/finance")]
public class SellerFinanceController(ShopyDbContext dbContext, IConfiguration configuration) : ControllerBase
{
    [HttpGet("balance")]
    public async Task<ActionResult<StoreBalanceDto>> GetBalance()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var balance = await dbContext.StoreBalances.SingleOrDefaultAsync(b => b.StoreId == storeId);

        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var monthlyTransactions = await dbContext.BalanceTransactions
            .Where(t => t.StoreId == storeId && t.CreatedAt >= monthStart)
            .ToListAsync();

        var monthlyEarning = monthlyTransactions
            .Where(t => t.Type is BalanceTransactionType.SaleIncome or BalanceTransactionType.Commission)
            .Sum(t => t.Amount);
        var monthlyCommission = Math.Abs(monthlyTransactions
            .Where(t => t.Type == BalanceTransactionType.Commission)
            .Sum(t => t.Amount));

        var completedCount = await dbContext.SubOrders.CountAsync(
            so => so.StoreId == storeId && so.Status == SubOrderStatus.Completed
                && so.CompletedAt != null && so.CompletedAt >= monthStart);

        return Ok(new StoreBalanceDto(
            balance?.AvailableBalance ?? 0,
            balance?.PendingBalance ?? 0,
            balance?.TotalEarning ?? 0,
            monthlyEarning,
            monthlyCommission,
            completedCount));
    }

    [HttpGet("transactions")]
    public async Task<ActionResult<PagedResult<BalanceTransactionDto>>> GetTransactions(
        [FromQuery] string? type, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.BalanceTransactions.Where(t => t.StoreId == storeId);
        query = type switch
        {
            "income" => query.Where(t => t.Type == BalanceTransactionType.SaleIncome),
            "withdrawal" => query.Where(t => t.Type == BalanceTransactionType.Withdrawal || t.Type == BalanceTransactionType.WithdrawalFee),
            _ => query,
        };
        query = query.OrderByDescending(t => t.CreatedAt);

        var totalCount = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new BalanceTransactionDto(t.Id, t.Type.ToString(), t.Amount, t.BalanceAfter, t.Description, t.CreatedAt))
            .ToListAsync();

        return Ok(new PagedResult<BalanceTransactionDto>(items, page, pageSize, totalCount));
    }

    [HttpPost("withdrawals")]
    public async Task<ActionResult<WithdrawalDto>> RequestWithdrawal(RequestWithdrawalRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var bankAccount = await dbContext.BankAccounts
            .SingleOrDefaultAsync(a => a.Id == request.BankAccountId && a.StoreId == storeId);
        if (bankAccount is null)
        {
            return BadRequest(new { message = "Rekening tidak ditemukan." });
        }
        if (!bankAccount.IsVerified)
        {
            return BadRequest(new { message = "Rekening belum terverifikasi." });
        }

        var minWithdrawal = configuration.GetValue("Platform:MinWithdrawal", 50000m);
        if (request.Amount < minWithdrawal)
        {
            return BadRequest(new { message = $"Minimal pencairan Rp{minWithdrawal:N0}." });
        }

        var balance = await dbContext.StoreBalances.SingleOrDefaultAsync(b => b.StoreId == storeId);
        if (balance is null || request.Amount > balance.AvailableBalance)
        {
            return BadRequest(new { message = "Saldo tidak mencukupi." });
        }

        var maxPerDay = configuration.GetValue("Platform:MaxWithdrawalsPerDay", 3);
        var todayStart = DateTime.UtcNow.Date;
        var todayCount = await dbContext.Withdrawals.CountAsync(w => w.StoreId == storeId && w.RequestedAt >= todayStart);
        if (todayCount >= maxPerDay)
        {
            return BadRequest(new { message = $"Maksimal {maxPerDay}x pencairan per hari." });
        }

        var adminFee = configuration.GetValue("Platform:WithdrawalAdminFee", 2500m);
        var netAmount = request.Amount - adminFee;
        if (netAmount <= 0)
        {
            return BadRequest(new { message = "Jumlah pencairan terlalu kecil setelah biaya admin." });
        }

        var now = DateTime.UtcNow;
        var withdrawal = new Withdrawal
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            BankAccountId = bankAccount.Id,
            Amount = request.Amount,
            AdminFee = adminFee,
            NetAmount = netAmount,
            Status = WithdrawalStatus.Pending,
            RequestedAt = now,
        };
        dbContext.Withdrawals.Add(withdrawal);

        var maskedAccount = MaskAccountNumber(bankAccount.AccountNumber);

        balance.AvailableBalance -= netAmount;
        dbContext.BalanceTransactions.Add(new BalanceTransaction
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            Type = BalanceTransactionType.Withdrawal,
            Amount = -netAmount,
            BalanceAfter = balance.AvailableBalance,
            WithdrawalId = withdrawal.Id,
            Description = $"Pencairan ke {bankAccount.BankName} {maskedAccount}",
            CreatedAt = now,
        });

        balance.AvailableBalance -= adminFee;
        dbContext.BalanceTransactions.Add(new BalanceTransaction
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            Type = BalanceTransactionType.WithdrawalFee,
            Amount = -adminFee,
            BalanceAfter = balance.AvailableBalance,
            WithdrawalId = withdrawal.Id,
            Description = "Biaya admin pencairan",
            CreatedAt = now,
        });

        balance.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        return Ok(ToWithdrawalDto(withdrawal, bankAccount));
    }

    [HttpGet("withdrawals")]
    public async Task<ActionResult<PagedResult<WithdrawalDto>>> GetWithdrawals(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Withdrawals
            .Where(w => w.StoreId == storeId)
            .Include(w => w.BankAccount)
            .OrderByDescending(w => w.RequestedAt);

        var totalCount = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return Ok(new PagedResult<WithdrawalDto>(
            items.Select(w => ToWithdrawalDto(w, w.BankAccount)).ToList(), page, pageSize, totalCount));
    }

    [HttpGet("reports/earnings")]
    public async Task<IActionResult> GetEarningsReport([FromQuery] DateTime? from, [FromQuery] DateTime? to)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var query = dbContext.BalanceTransactions.Where(t => t.StoreId == storeId);
        if (from is not null)
        {
            query = query.Where(t => t.CreatedAt >= from.Value);
        }
        if (to is not null)
        {
            query = query.Where(t => t.CreatedAt <= to.Value);
        }

        var items = await query.OrderBy(t => t.CreatedAt).ToListAsync();

        var csv = new StringBuilder();
        csv.AppendLine("Tanggal,Tipe,Deskripsi,Jumlah,Saldo Setelah");
        foreach (var t in items)
        {
            var amount = t.Amount.ToString(CultureInfo.InvariantCulture);
            var balanceAfter = t.BalanceAfter.ToString(CultureInfo.InvariantCulture);
            csv.AppendLine($"{t.CreatedAt:yyyy-MM-dd HH:mm},{t.Type},{EscapeCsv(t.Description)},{amount},{balanceAfter}");
        }

        var bytes = Encoding.UTF8.GetBytes(csv.ToString());
        return File(bytes, "text/csv", $"laporan-penghasilan-{DateTime.UtcNow:yyyyMMdd}.csv");
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private static string MaskAccountNumber(string accountNumber)
    {
        return accountNumber.Length <= 4 ? accountNumber : $"****{accountNumber[^4..]}";
    }

    private static string EscapeCsv(string? value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return string.Empty;
        }
        return value.Contains(',') || value.Contains('"') ? $"\"{value.Replace("\"", "\"\"")}\"" : value;
    }

    private static WithdrawalDto ToWithdrawalDto(Withdrawal w, BankAccount bankAccount) => new(
        w.Id, w.Amount, w.AdminFee, w.NetAmount, w.Status.ToString(), bankAccount.BankName,
        MaskAccountNumber(bankAccount.AccountNumber), w.RequestedAt, w.ProcessedAt);
}
