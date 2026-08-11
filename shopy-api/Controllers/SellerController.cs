using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Auth;
using shopy_api.Models.Sellers;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/seller")]
public class SellerController(
    ShopyDbContext dbContext,
    UserManager<ApplicationUser> userManager,
    ITokenService tokenService) : ControllerBase
{
    [HttpGet("me")]
    public async Task<ActionResult<SellerMeResponse>> Me()
    {
        var userId = User.GetUserId();
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return Unauthorized();
        }

        var store = await dbContext.Stores.SingleOrDefaultAsync(s => s.OwnerUserId == userId);

        return Ok(new SellerMeResponse(user.Id, user.Email ?? string.Empty, user.FullName, ToDto(store)));
    }

    [HttpPost("store")]
    public async Task<ActionResult<AuthResponse>> OpenStore(OpenStoreRequest request)
    {
        var userId = User.GetUserId();

        if (await dbContext.Stores.AnyAsync(s => s.OwnerUserId == userId))
        {
            return Conflict(new { message = "Kamu sudah punya toko." });
        }

        if (await dbContext.Stores.AnyAsync(s => s.Slug == request.Slug))
        {
            return Conflict(new { message = "URL toko sudah dipakai, coba yang lain." });
        }

        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return Unauthorized();
        }

        var store = new Store
        {
            Id = Guid.NewGuid(),
            OwnerUserId = userId,
            Name = request.Name,
            Slug = request.Slug,
            Description = request.Description,
            PhoneNumber = request.PhoneNumber,
            Status = StoreStatus.Pending,
            IsOpen = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        dbContext.Stores.Add(store);

        dbContext.StoreAddresses.Add(new StoreAddress
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Label = request.AddressLabel,
            PicName = request.AddressPicName,
            PhoneNumber = request.AddressPhoneNumber,
            FullAddress = request.AddressFullAddress,
            City = request.AddressCity,
            Province = request.AddressProvince,
            PostalCode = request.AddressPostalCode,
            IsDefault = true,
        });

        dbContext.StoreBalances.Add(new StoreBalance
        {
            StoreId = store.Id,
            AvailableBalance = 0,
            PendingBalance = 0,
            TotalEarning = 0,
            UpdatedAt = DateTime.UtcNow,
        });

        await userManager.AddToRoleAsync(user, "Seller");
        await dbContext.SaveChangesAsync();

        // Token baru — otomatis bawa claim role=Seller & store_id terbaru (lihat TokenService),
        // supaya client tidak perlu logout/login ulang setelah buka toko.
        var accessToken = await tokenService.GenerateAccessTokenAsync(user);
        var refreshToken = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Token = tokenService.GenerateRefreshToken(),
            ExpiresAt = tokenService.GetRefreshTokenExpiry(),
            CreatedAt = DateTime.UtcNow,
        };
        dbContext.RefreshTokens.Add(refreshToken);
        await dbContext.SaveChangesAsync();

        return Ok(new AuthResponse(
            accessToken.Token,
            accessToken.ExpiresAt,
            refreshToken.Token,
            user.Id,
            user.Email ?? string.Empty,
            user.FullName));
    }

    [HttpGet("store/status")]
    public async Task<ActionResult<StoreSummaryDto>> GetStoreStatus()
    {
        var userId = User.GetUserId();
        var store = await dbContext.Stores.SingleOrDefaultAsync(s => s.OwnerUserId == userId);
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        return Ok(ToDto(store));
    }

    [Authorize(Roles = "Seller")]
    [HttpGet("store")]
    public async Task<ActionResult<StoreDetailDto>> GetStore()
    {
        var store = await GetMyStoreAsync();
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        return Ok(ToDetailDto(store));
    }

    [Authorize(Roles = "Seller")]
    [HttpPut("store")]
    public async Task<ActionResult<StoreDetailDto>> UpdateStore(UpdateStoreRequest request)
    {
        var store = await GetMyStoreAsync();
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        store.Name = request.Name;
        store.Description = request.Description;
        store.LogoUrl = request.LogoUrl;
        store.BannerUrl = request.BannerUrl;
        store.PhoneNumber = request.PhoneNumber;
        store.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync();
        return Ok(ToDetailDto(store));
    }

    [Authorize(Roles = "Seller")]
    [HttpPatch("store/open")]
    public async Task<ActionResult<StoreDetailDto>> SetStoreOpen(SetStoreOpenRequest request)
    {
        var store = await GetMyStoreAsync();
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        store.IsOpen = request.IsOpen;
        store.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync();
        return Ok(ToDetailDto(store));
    }

    [Authorize(Roles = "Seller")]
    [HttpGet("store/documents")]
    public async Task<ActionResult<IReadOnlyList<StoreDocumentDto>>> GetDocuments()
    {
        var store = await GetMyStoreAsync();
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var documents = await dbContext.StoreDocuments
            .Where(d => d.StoreId == store.Id)
            .OrderByDescending(d => d.Id)
            .Select(d => new StoreDocumentDto(d.Id, d.Type.ToString(), d.FileUrl, d.Status.ToString(), d.RejectReason, d.ReviewedAt))
            .ToListAsync();

        return Ok(documents);
    }

    [Authorize(Roles = "Seller")]
    [HttpPost("store/documents")]
    public async Task<ActionResult<StoreDocumentDto>> CreateDocument(CreateStoreDocumentRequest request)
    {
        var store = await GetMyStoreAsync();
        if (store is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        if (!Enum.TryParse<StoreDocumentType>(request.Type, out var type))
        {
            return BadRequest(new { message = "Jenis dokumen tidak dikenal." });
        }

        var document = new StoreDocument
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Type = type,
            FileUrl = request.FileUrl,
            Status = DocumentReviewStatus.Pending,
        };
        dbContext.StoreDocuments.Add(document);
        await dbContext.SaveChangesAsync();

        return Ok(new StoreDocumentDto(
            document.Id, document.Type.ToString(), document.FileUrl, document.Status.ToString(),
            document.RejectReason, document.ReviewedAt));
    }

    private Task<Store?> GetMyStoreAsync()
    {
        var userId = User.GetUserId();
        return dbContext.Stores.SingleOrDefaultAsync(s => s.OwnerUserId == userId);
    }

    private static StoreSummaryDto? ToDto(Store? store) => store is null
        ? null
        : new StoreSummaryDto(
            store.Id, store.Name, store.Slug, store.Description, store.LogoUrl,
            store.PhoneNumber, store.Status.ToString(), store.IsOpen);

    private static StoreDetailDto ToDetailDto(Store store) => new(
        store.Id, store.Name, store.Slug, store.Description, store.LogoUrl, store.BannerUrl,
        store.PhoneNumber, store.Status.ToString(), store.IsOpen, store.RatingAverage, store.RatingCount,
        store.ProductCount, store.FollowerCount);
}
