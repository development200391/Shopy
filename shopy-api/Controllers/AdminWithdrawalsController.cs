using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Admin;
using shopy_api.Models.Catalog;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>
/// Proses pencairan dana seller (TASKSELLER.md Fase 9). Uang sudah dipotong dari
/// <c>StoreBalance.AvailableBalance</c> sejak seller REQUEST withdrawal
/// (<c>SellerFinanceController.RequestWithdrawal</c>), jadi <c>Processing</c>/<c>Completed</c>
/// di sini murni ubah status (tidak ada pergerakan uang lagi); <c>Rejected</c> yang perlu
/// refund balik ke saldo toko.
/// </summary>
[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/withdrawals")]
public class AdminWithdrawalsController(ShopyDbContext dbContext, INotificationService notificationService) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<AdminWithdrawalListItemDto>>> GetWithdrawals(
        [FromQuery] string? status, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Withdrawals.Include(w => w.Store).Include(w => w.BankAccount).AsQueryable();
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<WithdrawalStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(w => w.Status == parsedStatus);
        }
        query = query.OrderByDescending(w => w.RequestedAt);

        var totalCount = await query.CountAsync();
        var withdrawals = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return Ok(new PagedResult<AdminWithdrawalListItemDto>(withdrawals.Select(ToDto).ToList(), page, pageSize, totalCount));
    }

    [HttpPatch("{id:guid}")]
    public async Task<ActionResult<AdminWithdrawalListItemDto>> UpdateStatus(Guid id, UpdateWithdrawalStatusRequest request)
    {
        if (!Enum.TryParse<WithdrawalStatus>(request.Status, true, out var newStatus))
        {
            return BadRequest(new { message = "Status tidak dikenal." });
        }

        var withdrawal = await dbContext.Withdrawals
            .Include(w => w.Store)
            .Include(w => w.BankAccount)
            .SingleOrDefaultAsync(w => w.Id == id);
        if (withdrawal is null)
        {
            return NotFound(new { message = "Pencairan tidak ditemukan." });
        }
        if (withdrawal.Status is WithdrawalStatus.Completed or WithdrawalStatus.Rejected)
        {
            return BadRequest(new { message = "Pencairan ini sudah final, tidak bisa diubah lagi." });
        }
        if (newStatus == WithdrawalStatus.Processing && withdrawal.Status != WithdrawalStatus.Pending)
        {
            return BadRequest(new { message = "Cuma pencairan yang masih menunggu yang bisa diproses." });
        }
        if (newStatus == WithdrawalStatus.Pending)
        {
            return BadRequest(new { message = "Transisi status tidak valid." });
        }

        var now = DateTime.UtcNow;
        withdrawal.Status = newStatus;
        withdrawal.RejectReason = newStatus == WithdrawalStatus.Rejected ? request.Reason : null;

        if (newStatus is WithdrawalStatus.Completed or WithdrawalStatus.Rejected)
        {
            withdrawal.ProcessedAt = now;
        }

        if (newStatus == WithdrawalStatus.Rejected)
        {
            // Dana sudah kepotong saat request (lihat SellerFinanceController.RequestWithdrawal)
            // — dikembalikan penuh (netAmount + adminFee) karena pencairannya batal.
            var balance = await dbContext.StoreBalances.SingleAsync(b => b.StoreId == withdrawal.StoreId);
            balance.AvailableBalance += withdrawal.Amount;
            balance.UpdatedAt = now;
            dbContext.BalanceTransactions.Add(new BalanceTransaction
            {
                Id = Guid.NewGuid(),
                StoreId = withdrawal.StoreId,
                Type = BalanceTransactionType.Refund,
                Amount = withdrawal.Amount,
                BalanceAfter = balance.AvailableBalance,
                WithdrawalId = withdrawal.Id,
                Description = "Pencairan ditolak — dana dikembalikan",
                CreatedAt = now,
            });
        }

        await dbContext.SaveChangesAsync();

        if (newStatus == WithdrawalStatus.Completed)
        {
            await notificationService.NotifyWithdrawalCompletedAsync(withdrawal, withdrawal.Store);
        }

        return Ok(ToDto(withdrawal));
    }

    private static string MaskAccountNumber(string accountNumber) =>
        accountNumber.Length <= 4 ? accountNumber : $"****{accountNumber[^4..]}";

    private static AdminWithdrawalListItemDto ToDto(Withdrawal w) => new(
        w.Id, w.Store.Name, w.Amount, w.AdminFee, w.NetAmount, w.Status.ToString(),
        w.BankAccount.BankName, MaskAccountNumber(w.BankAccount.AccountNumber), w.RequestedAt, w.ProcessedAt);
}
