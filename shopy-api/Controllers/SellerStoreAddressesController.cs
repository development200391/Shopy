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
[Route("api/seller/store/addresses")]
public class SellerStoreAddressesController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<StoreAddressDto>>> GetAddresses()
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var addresses = await dbContext.StoreAddresses
            .Where(a => a.StoreId == storeId)
            .OrderByDescending(a => a.IsDefault)
            .Select(a => ToDto(a))
            .ToListAsync();

        return Ok(addresses);
    }

    [HttpPost]
    public async Task<ActionResult<StoreAddressDto>> CreateAddress(SaveStoreAddressRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        if (storeId is null)
        {
            return NotFound(new { message = "Kamu belum punya toko." });
        }

        var isFirstAddress = !await dbContext.StoreAddresses.AnyAsync(a => a.StoreId == storeId);
        var makeDefault = request.IsDefault || isFirstAddress;

        if (makeDefault)
        {
            await UnsetCurrentDefaultAsync(storeId.Value);
        }

        var address = new StoreAddress
        {
            Id = Guid.NewGuid(),
            StoreId = storeId.Value,
            Label = request.Label,
            PicName = request.PicName,
            PhoneNumber = request.PhoneNumber,
            FullAddress = request.FullAddress,
            City = request.City,
            Province = request.Province,
            PostalCode = request.PostalCode,
            IsDefault = makeDefault,
        };
        dbContext.StoreAddresses.Add(address);
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(address));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<StoreAddressDto>> UpdateAddress(Guid id, SaveStoreAddressRequest request)
    {
        var storeId = await GetMyStoreIdAsync();
        var address = await dbContext.StoreAddresses.SingleOrDefaultAsync(a => a.Id == id && a.StoreId == storeId);
        if (address is null)
        {
            return NotFound(new { message = "Alamat tidak ditemukan." });
        }

        address.Label = request.Label;
        address.PicName = request.PicName;
        address.PhoneNumber = request.PhoneNumber;
        address.FullAddress = request.FullAddress;
        address.City = request.City;
        address.Province = request.Province;
        address.PostalCode = request.PostalCode;

        if (request.IsDefault && !address.IsDefault)
        {
            await UnsetCurrentDefaultAsync(storeId!.Value);
            address.IsDefault = true;
        }

        await dbContext.SaveChangesAsync();
        return Ok(ToDto(address));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteAddress(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var address = await dbContext.StoreAddresses.SingleOrDefaultAsync(a => a.Id == id && a.StoreId == storeId);
        if (address is null)
        {
            return NotFound(new { message = "Alamat tidak ditemukan." });
        }

        address.IsDeleted = true;
        var wasDefault = address.IsDefault;
        address.IsDefault = false;
        await dbContext.SaveChangesAsync();

        if (wasDefault)
        {
            var nextDefault = await dbContext.StoreAddresses
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
    public async Task<ActionResult<StoreAddressDto>> SetDefault(Guid id)
    {
        var storeId = await GetMyStoreIdAsync();
        var address = await dbContext.StoreAddresses.SingleOrDefaultAsync(a => a.Id == id && a.StoreId == storeId);
        if (address is null)
        {
            return NotFound(new { message = "Alamat tidak ditemukan." });
        }

        await UnsetCurrentDefaultAsync(storeId!.Value);
        address.IsDefault = true;
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(address));
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
        var current = await dbContext.StoreAddresses
            .Where(a => a.StoreId == storeId && a.IsDefault)
            .ToListAsync();
        foreach (var address in current)
        {
            address.IsDefault = false;
        }
    }

    private static StoreAddressDto ToDto(StoreAddress a) => new(
        a.Id, a.Label, a.PicName, a.PhoneNumber, a.FullAddress, a.City, a.Province, a.PostalCode, a.IsDefault);
}
