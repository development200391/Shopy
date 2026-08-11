using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize(Roles = "Seller")]
[Route("api/seller/bank-accounts")]
public class SellerBankAccountsController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<BankAccountDto>>> GetBankAccounts()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var accounts = await dbContext.BankAccounts
            .Where(a => a.StoreId == storeId)
            .OrderByDescending(a => a.IsDefault)
            .Select(a => ToDto(a))
            .ToListAsync();

        return Ok(accounts);
    }

    [HttpPost]
    public async Task<ActionResult<BankAccountDto>> CreateBankAccount(SaveBankAccountRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var isFirstAccount = !await dbContext.BankAccounts.AnyAsync(a => a.StoreId == storeId);
        var makeDefault = request.IsDefault || isFirstAccount;

        if (makeDefault)
        {
            await UnsetCurrentDefaultAsync(storeId.Value);
        }

        var account = new BankAccount
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            BankCode = request.BankCode,
            BankName = request.BankName,
            AccountNumber = request.AccountNumber,
            AccountHolderName = request.AccountHolderName,
            IsVerified = false,
            IsDefault = makeDefault,
        };
        dbContext.BankAccounts.Add(account);
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(account));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteBankAccount(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var account = await dbContext.BankAccounts.SingleOrDefaultAsync(a => a.Id == id && a.StoreId == storeId);
        if (account is null)
        {
            return NotFound(new { message = "Rekening tidak ditemukan." });
        }

        account.IsDeleted = true;
        var wasDefault = account.IsDefault;
        account.IsDefault = false;
        await dbContext.SaveChangesAsync();

        if (wasDefault)
        {
            var nextDefault = await dbContext.BankAccounts
                .Where(a => a.StoreId == storeId)
                .FirstOrDefaultAsync();
            if (nextDefault is not null)
            {
                nextDefault.IsDefault = true;
                await dbContext.SaveChangesAsync();
            }
        }

        return NoContent();
    }

    [HttpPatch("{id:guid}/default")]
    public async Task<ActionResult<BankAccountDto>> SetDefault(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var account = await dbContext.BankAccounts.SingleOrDefaultAsync(a => a.Id == id && a.StoreId == storeId);
        if (account is null)
        {
            return NotFound(new { message = "Rekening tidak ditemukan." });
        }

        await UnsetCurrentDefaultAsync(storeId!.Value);
        account.IsDefault = true;
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(account));
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private async Task UnsetCurrentDefaultAsync(Guid storeId)
    {
        var current = await dbContext.BankAccounts
            .Where(a => a.StoreId == storeId && a.IsDefault)
            .ToListAsync();
        foreach (var account in current)
        {
            account.IsDefault = false;
        }
    }

    private static BankAccountDto ToDto(BankAccount a) => new(
        a.Id, a.BankCode, a.BankName, a.AccountNumber, a.AccountHolderName, a.IsVerified, a.IsDefault);
}
