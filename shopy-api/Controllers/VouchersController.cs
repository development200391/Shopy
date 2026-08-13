using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models.Vouchers;
using shopy_api.Services;

namespace shopy_api.Controllers;

/// <summary>Sisi pembeli — validasi kode voucher toko sebelum/selama checkout.</summary>
[ApiController]
[Authorize]
[Route("api/vouchers")]
public class VouchersController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpPost("validate")]
    public async Task<ActionResult<ValidateVoucherResponse>> Validate(ValidateVoucherRequest request)
    {
        var code = request.Code.Trim().ToUpperInvariant();
        var voucher = await dbContext.Vouchers
            .SingleOrDefaultAsync(v => v.StoreId == request.StoreId && v.Code == code);

        var result = VoucherValidationHelper.Validate(voucher, request.Subtotal, request.ShippingCost, DateTime.UtcNow);

        return Ok(new ValidateVoucherResponse(
            result.Valid, result.Message, result.Valid ? voucher!.Id : null, voucher?.Type.ToString(), result.DiscountAmount));
    }
}
