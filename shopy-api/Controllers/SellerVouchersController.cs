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
[Route("api/seller/vouchers")]
public class SellerVouchersController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<VoucherDto>>> GetVouchers()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var vouchers = await dbContext.Vouchers
            .Where(v => v.StoreId == storeId)
            .OrderByDescending(v => v.StartAt)
            .ToListAsync();

        var stats = await GetStatsAsync(vouchers.Select(v => v.Id).ToList());
        return Ok(vouchers.Select(v => ToDto(v, stats)).ToList());
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<VoucherDto>> GetVoucher(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var voucher = await dbContext.Vouchers.SingleOrDefaultAsync(v => v.Id == id && v.StoreId == storeId);
        if (voucher is null)
        {
            return NotFound(new { message = "Voucher tidak ditemukan." });
        }

        var stats = await GetStatsAsync([voucher.Id]);
        return Ok(ToDto(voucher, stats));
    }

    [HttpPost]
    public async Task<ActionResult<VoucherDto>> CreateVoucher(SaveVoucherRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var (ok, error, type) = ParseAndValidate(request);
        if (!ok)
        {
            return BadRequest(new { message = error });
        }

        var code = request.Code.Trim().ToUpperInvariant();
        if (await dbContext.Vouchers.AnyAsync(v => v.StoreId == storeId && v.Code == code))
        {
            return Conflict(new { message = "Kode voucher sudah dipakai." });
        }

        var voucher = new Voucher
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            Code = code,
            Type = type,
            Value = request.Value,
            MaxDiscount = request.MaxDiscount,
            MinPurchase = request.MinPurchase,
            Quota = request.Quota,
            UsedCount = 0,
            StartAt = request.StartAt,
            EndAt = request.EndAt,
            IsActive = true,
        };
        dbContext.Vouchers.Add(voucher);
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(voucher, []));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<VoucherDto>> UpdateVoucher(Guid id, SaveVoucherRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var voucher = await dbContext.Vouchers.SingleOrDefaultAsync(v => v.Id == id && v.StoreId == storeId);
        if (voucher is null)
        {
            return NotFound(new { message = "Voucher tidak ditemukan." });
        }

        var (ok, error, type) = ParseAndValidate(request);
        if (!ok)
        {
            return BadRequest(new { message = error });
        }

        var code = request.Code.Trim().ToUpperInvariant();
        if (code != voucher.Code && await dbContext.Vouchers.AnyAsync(v => v.StoreId == storeId && v.Code == code && v.Id != id))
        {
            return Conflict(new { message = "Kode voucher sudah dipakai." });
        }

        voucher.Code = code;
        voucher.Type = type;
        voucher.Value = request.Value;
        voucher.MaxDiscount = request.MaxDiscount;
        voucher.MinPurchase = request.MinPurchase;
        voucher.Quota = request.Quota;
        voucher.StartAt = request.StartAt;
        voucher.EndAt = request.EndAt;
        await dbContext.SaveChangesAsync();

        var stats = await GetStatsAsync([voucher.Id]);
        return Ok(ToDto(voucher, stats));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteVoucher(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var voucher = await dbContext.Vouchers.SingleOrDefaultAsync(v => v.Id == id && v.StoreId == storeId);
        if (voucher is null)
        {
            return NotFound(new { message = "Voucher tidak ditemukan." });
        }

        voucher.IsDeleted = true;
        await dbContext.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("{id:guid}/active")]
    public async Task<ActionResult<VoucherDto>> SetActive(Guid id, SetVoucherActiveRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var voucher = await dbContext.Vouchers.SingleOrDefaultAsync(v => v.Id == id && v.StoreId == storeId);
        if (voucher is null)
        {
            return NotFound(new { message = "Voucher tidak ditemukan." });
        }

        voucher.IsActive = request.IsActive;
        await dbContext.SaveChangesAsync();

        var stats = await GetStatsAsync([voucher.Id]);
        return Ok(ToDto(voucher, stats));
    }

    private async Task<Dictionary<Guid, (decimal DiscountGiven, decimal OrderValue)>> GetStatsAsync(List<Guid> voucherIds)
    {
        if (voucherIds.Count == 0)
        {
            return [];
        }

        var usages = await dbContext.VoucherUsages
            .Where(u => voucherIds.Contains(u.VoucherId))
            .Include(u => u.SubOrder)
            .ToListAsync();

        return usages
            .GroupBy(u => u.VoucherId)
            .ToDictionary(g => g.Key, g => (g.Sum(u => u.DiscountAmount), g.Sum(u => u.SubOrder.Subtotal)));
    }

    private static (bool Ok, string? Error, VoucherType Type) ParseAndValidate(SaveVoucherRequest request)
    {
        if (!Enum.TryParse<VoucherType>(request.Type, out var type))
        {
            return (false, "Tipe voucher tidak dikenal.", default);
        }
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            return (false, "Kode voucher wajib diisi.", default);
        }
        if (request.Value <= 0)
        {
            return (false, "Nilai voucher harus lebih dari 0.", default);
        }
        if (type == VoucherType.Percentage && request.Value > 100)
        {
            return (false, "Persentase diskon maksimal 100%.", default);
        }
        if (request.EndAt <= request.StartAt)
        {
            return (false, "Tanggal berakhir harus setelah tanggal mulai.", default);
        }
        return (true, null, type);
    }

    private async Task<Guid?> GetMyStoreIdAsync()
    {
        var userId = User.GetUserId();
        return await dbContext.Stores
            .Where(s => s.OwnerUserId == userId)
            .Select(s => (Guid?)s.Id)
            .SingleOrDefaultAsync();
    }

    private static VoucherDto ToDto(Voucher v, Dictionary<Guid, (decimal DiscountGiven, decimal OrderValue)> stats)
    {
        var (discountGiven, orderValue) = stats.TryGetValue(v.Id, out var s) ? s : (0m, 0m);
        return new VoucherDto(
            v.Id, v.Code, v.Type.ToString(), v.Value, v.MaxDiscount, v.MinPurchase, v.Quota, v.UsedCount,
            v.StartAt, v.EndAt, v.IsActive, ComputeStatus(v), discountGiven, orderValue);
    }

    private static string ComputeStatus(Voucher v)
    {
        var now = DateTime.UtcNow;
        if (v.EndAt < now || (v.Quota is not null && v.UsedCount >= v.Quota))
        {
            return "Ended";
        }
        if (v.StartAt > now)
        {
            return "Scheduled";
        }
        return v.IsActive ? "Active" : "Inactive";
    }
}
