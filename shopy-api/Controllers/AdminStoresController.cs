using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Admin;
using shopy_api.Models.Catalog;
using shopy_api.Models.Sellers;

namespace shopy_api.Controllers;

/// <summary>
/// Verifikasi & moderasi toko (TASKSELLER.md Fase 9). Admin tidak terikat 1 toko seperti
/// controller seller — tidak ada konsep `GetMyStoreIdAsync()` di sini, semua endpoint
/// beroperasi lintas toko.
/// </summary>
[ApiController]
[Authorize(Roles = "Admin")]
[Route("api/admin/stores")]
public class AdminStoresController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<AdminStoreListItemDto>>> GetStores(
        [FromQuery] string? status, [FromQuery] string? q, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 50);

        var query = dbContext.Stores.Include(s => s.OwnerUser).AsQueryable();
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<StoreStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(s => s.Status == parsedStatus);
        }
        if (!string.IsNullOrWhiteSpace(q))
        {
            var term = $"%{q.Trim()}%";
            query = query.Where(s => EF.Functions.ILike(s.Name, term));
        }
        query = query.OrderByDescending(s => s.CreatedAt);

        var totalCount = await query.CountAsync();
        var stores = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

        return Ok(new PagedResult<AdminStoreListItemDto>(stores.Select(ToDto).ToList(), page, pageSize, totalCount));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<AdminStoreDetailDto>> GetStore(Guid id)
    {
        var store = await LoadAsync(id);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }

        var documents = await dbContext.StoreDocuments
            .Where(d => d.StoreId == id)
            .OrderByDescending(d => d.Id)
            .Select(d => new StoreDocumentDto(d.Id, d.Type.ToString(), d.FileUrl, d.Status.ToString(), d.RejectReason, d.ReviewedAt))
            .ToListAsync();

        return Ok(new AdminStoreDetailDto(
            store.Id, store.Name, store.Slug, store.Description, store.LogoUrl, store.BannerUrl, store.PhoneNumber,
            store.OwnerUser.FullName, store.OwnerUser.Email ?? string.Empty, store.Status.ToString(), store.ModerationReason,
            store.RatingAverage, store.RatingCount, store.ProductCount, store.FollowerCount, store.CreatedAt, documents));
    }

    [HttpPost("{id:guid}/approve")]
    public async Task<ActionResult<AdminStoreListItemDto>> Approve(Guid id)
    {
        var store = await LoadAsync(id);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }
        if (store.Status != StoreStatus.Pending)
        {
            return BadRequest(new { message = "Toko ini tidak sedang menunggu verifikasi." });
        }

        store.Status = StoreStatus.Active;
        store.ModerationReason = null;
        store.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return Ok(ToDto(store));
    }

    [HttpPost("{id:guid}/reject")]
    public async Task<ActionResult<AdminStoreListItemDto>> Reject(Guid id, RejectStoreRequest request)
    {
        var store = await LoadAsync(id);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }
        if (store.Status != StoreStatus.Pending)
        {
            return BadRequest(new { message = "Toko ini tidak sedang menunggu verifikasi." });
        }

        store.Status = StoreStatus.Rejected;
        store.ModerationReason = request.Reason;
        store.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return Ok(ToDto(store));
    }

    [HttpPost("{id:guid}/suspend")]
    public async Task<ActionResult<AdminStoreListItemDto>> Suspend(Guid id, SuspendStoreRequest request)
    {
        var store = await LoadAsync(id);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }
        if (store.Status != StoreStatus.Active)
        {
            return BadRequest(new { message = "Cuma toko aktif yang bisa disuspend." });
        }

        store.Status = StoreStatus.Suspended;
        store.ModerationReason = request.Reason;
        store.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return Ok(ToDto(store));
    }

    [HttpPost("{id:guid}/activate")]
    public async Task<ActionResult<AdminStoreListItemDto>> Activate(Guid id)
    {
        var store = await LoadAsync(id);
        if (store is null)
        {
            return NotFound(new { message = "Toko tidak ditemukan." });
        }
        if (store.Status != StoreStatus.Suspended)
        {
            return BadRequest(new { message = "Cuma toko yang disuspend yang bisa diaktifkan lagi." });
        }

        store.Status = StoreStatus.Active;
        store.ModerationReason = null;
        store.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
        return Ok(ToDto(store));
    }

    private Task<Store?> LoadAsync(Guid id) =>
        dbContext.Stores.Include(s => s.OwnerUser).SingleOrDefaultAsync(s => s.Id == id);

    private static AdminStoreListItemDto ToDto(Store s) => new(
        s.Id, s.Name, s.Slug, s.OwnerUser.FullName, s.OwnerUser.Email ?? string.Empty,
        s.Status.ToString(), s.ModerationReason, s.ProductCount, s.CreatedAt);
}
