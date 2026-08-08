using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Addresses;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/addresses")]
public class AddressesController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<AddressDto>>> GetAddresses()
    {
        var userId = User.GetUserId();
        var addresses = await dbContext.Addresses
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .Select(a => ToDto(a))
            .ToListAsync();

        return Ok(addresses);
    }

    [HttpPost]
    public async Task<ActionResult<AddressDto>> CreateAddress(SaveAddressRequest request)
    {
        var userId = User.GetUserId();
        var isFirstAddress = !await dbContext.Addresses.AnyAsync(a => a.UserId == userId);
        var makeDefault = request.IsDefault || isFirstAddress;

        if (makeDefault)
        {
            await UnsetCurrentDefaultAsync(userId);
        }

        var address = new Address
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Label = request.Label,
            RecipientName = request.RecipientName,
            PhoneNumber = request.PhoneNumber,
            FullAddress = request.FullAddress,
            City = request.City,
            Province = request.Province,
            PostalCode = request.PostalCode,
            IsDefault = makeDefault,
            CreatedAt = DateTime.UtcNow,
        };
        dbContext.Addresses.Add(address);
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(address));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<AddressDto>> UpdateAddress(Guid id, SaveAddressRequest request)
    {
        var userId = User.GetUserId();
        var address = await dbContext.Addresses.SingleOrDefaultAsync(a => a.Id == id && a.UserId == userId);
        if (address is null)
        {
            return NotFound(new { message = "Alamat tidak ditemukan." });
        }

        address.Label = request.Label;
        address.RecipientName = request.RecipientName;
        address.PhoneNumber = request.PhoneNumber;
        address.FullAddress = request.FullAddress;
        address.City = request.City;
        address.Province = request.Province;
        address.PostalCode = request.PostalCode;

        if (request.IsDefault && !address.IsDefault)
        {
            await UnsetCurrentDefaultAsync(userId);
            address.IsDefault = true;
        }

        await dbContext.SaveChangesAsync();
        return Ok(ToDto(address));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteAddress(Guid id)
    {
        var userId = User.GetUserId();
        var address = await dbContext.Addresses.SingleOrDefaultAsync(a => a.Id == id && a.UserId == userId);
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
            var nextDefault = await dbContext.Addresses
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CreatedAt)
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
    public async Task<ActionResult<AddressDto>> SetDefault(Guid id)
    {
        var userId = User.GetUserId();
        var address = await dbContext.Addresses.SingleOrDefaultAsync(a => a.Id == id && a.UserId == userId);
        if (address is null)
        {
            return NotFound(new { message = "Alamat tidak ditemukan." });
        }

        await UnsetCurrentDefaultAsync(userId);
        address.IsDefault = true;
        await dbContext.SaveChangesAsync();

        return Ok(ToDto(address));
    }

    private async Task UnsetCurrentDefaultAsync(Guid userId)
    {
        var current = await dbContext.Addresses
            .Where(a => a.UserId == userId && a.IsDefault)
            .ToListAsync();
        foreach (var address in current)
        {
            address.IsDefault = false;
        }
    }

    private static AddressDto ToDto(Address a) => new(
        a.Id, a.Label, a.RecipientName, a.PhoneNumber, a.FullAddress, a.City, a.Province, a.PostalCode, a.IsDefault);
}
