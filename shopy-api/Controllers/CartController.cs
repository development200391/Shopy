using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Carts;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Authorize]
[Route("api/cart")]
public class CartController(ShopyDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<CartDto>> GetCart()
    {
        var cart = await GetOrCreateCartAsync();
        return Ok(await ToDtoAsync(cart.Id));
    }

    [HttpPost("items")]
    public async Task<ActionResult<CartDto>> AddItem(AddCartItemRequest request)
    {
        if (request.Quantity < 1)
        {
            return BadRequest(new { message = "Jumlah harus minimal 1." });
        }

        var product = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == request.ProductId && p.IsActive);
        if (product is null)
        {
            return NotFound(new { message = "Produk tidak ditemukan." });
        }

        if (product.Stock <= 0)
        {
            return BadRequest(new { message = "Stok produk habis." });
        }

        var cart = await GetOrCreateCartAsync();
        var existingItem = await dbContext.CartItems
            .SingleOrDefaultAsync(ci => ci.CartId == cart.Id && ci.ProductId == request.ProductId);

        var now = DateTime.UtcNow;
        var quantity = Math.Min((existingItem?.Quantity ?? 0) + request.Quantity, product.Stock);

        if (existingItem is null)
        {
            dbContext.CartItems.Add(new CartItem
            {
                Id = Guid.NewGuid(),
                CartId = cart.Id,
                ProductId = product.Id,
                Quantity = quantity,
                CreatedAt = now,
                UpdatedAt = now,
            });
        }
        else
        {
            existingItem.Quantity = quantity;
            existingItem.UpdatedAt = now;
        }

        cart.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        return Ok(await ToDtoAsync(cart.Id));
    }

    [HttpPut("items/{itemId:guid}")]
    public async Task<ActionResult<CartDto>> UpdateItem(Guid itemId, UpdateCartItemRequest request)
    {
        if (request.Quantity < 1)
        {
            return BadRequest(new { message = "Jumlah harus minimal 1." });
        }

        var cart = await GetOrCreateCartAsync();
        var item = await dbContext.CartItems
            .Include(ci => ci.Product)
            .SingleOrDefaultAsync(ci => ci.Id == itemId && ci.CartId == cart.Id);
        if (item is null)
        {
            return NotFound(new { message = "Barang tidak ditemukan di keranjang." });
        }

        item.Quantity = Math.Min(request.Quantity, Math.Max(item.Product.Stock, 1));
        item.UpdatedAt = DateTime.UtcNow;
        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(await ToDtoAsync(cart.Id));
    }

    [HttpDelete("items/{itemId:guid}")]
    public async Task<ActionResult<CartDto>> RemoveItem(Guid itemId)
    {
        var cart = await GetOrCreateCartAsync();
        var item = await dbContext.CartItems.SingleOrDefaultAsync(ci => ci.Id == itemId && ci.CartId == cart.Id);
        if (item is null)
        {
            return NotFound(new { message = "Barang tidak ditemukan di keranjang." });
        }

        item.IsDeleted = true;
        item.UpdatedAt = DateTime.UtcNow;
        cart.UpdatedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(await ToDtoAsync(cart.Id));
    }

    [HttpDelete]
    public async Task<ActionResult<CartDto>> ClearCart()
    {
        var cart = await GetOrCreateCartAsync();
        var items = await dbContext.CartItems.Where(ci => ci.CartId == cart.Id).ToListAsync();

        var now = DateTime.UtcNow;
        foreach (var item in items)
        {
            item.IsDeleted = true;
            item.UpdatedAt = now;
        }
        cart.UpdatedAt = now;
        await dbContext.SaveChangesAsync();

        return Ok(await ToDtoAsync(cart.Id));
    }

    private async Task<Cart> GetOrCreateCartAsync()
    {
        var userId = User.GetUserId();
        var cart = await dbContext.Carts.SingleOrDefaultAsync(c => c.UserId == userId);
        if (cart is not null)
        {
            return cart;
        }

        cart = new Cart
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
        };
        dbContext.Carts.Add(cart);
        await dbContext.SaveChangesAsync();
        return cart;
    }

    private async Task<CartDto> ToDtoAsync(Guid cartId)
    {
        var items = await dbContext.CartItems
            .Where(ci => ci.CartId == cartId)
            .Include(ci => ci.Product)
            .OrderBy(ci => ci.CreatedAt)
            .Select(ci => new CartItemDto(
                ci.Id, ci.ProductId, ci.Product.Name, ci.Product.Slug, ci.Product.ImageUrl,
                ci.Product.Price, ci.Quantity, ci.Product.Stock, ci.Product.StoreId, ci.Product.Store.Name))
            .ToListAsync();

        return new CartDto(cartId, items);
    }
}
