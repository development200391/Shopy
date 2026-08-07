using Microsoft.EntityFrameworkCore;
using shopy_api.Models;

namespace shopy_api.Data;

// Data contoh untuk development, supaya endpoint katalog (Fase 2) ada isinya saat ditest.
// Hanya jalan di environment Development dan hanya kalau tabel Categories masih kosong.
public static class CatalogSeeder
{
    public static async Task SeedAsync(ShopyDbContext dbContext)
    {
        if (await dbContext.Categories.AnyAsync())
        {
            return;
        }

        var elektronik = NewCategory("Elektronik", "elektronik");
        var handphone = NewCategory("Handphone", "handphone", elektronik.Id);
        var laptop = NewCategory("Laptop", "laptop", elektronik.Id);
        var fashion = NewCategory("Fashion", "fashion");
        var fashionPria = NewCategory("Fashion Pria", "fashion-pria", fashion.Id);
        var fashionWanita = NewCategory("Fashion Wanita", "fashion-wanita", fashion.Id);
        var rumahTangga = NewCategory("Rumah Tangga", "rumah-tangga");
        var olahraga = NewCategory("Olahraga", "olahraga");

        dbContext.Categories.AddRange(
            elektronik, handphone, laptop, fashion, fashionPria, fashionWanita, rumahTangga, olahraga);

        dbContext.Products.AddRange(
            NewProduct(handphone.Id, "Smartphone X100", "smartphone-x100", 2_999_000, 25, 4.5m, 120),
            NewProduct(handphone.Id, "Smartphone Y200", "smartphone-y200", 4_499_000, 15, 4.2m, 87),
            NewProduct(laptop.Id, "Laptop Ultrabook 14\"", "laptop-ultrabook-14", 8_999_000, 10, 4.7m, 54),
            NewProduct(laptop.Id, "Laptop Gaming 15\"", "laptop-gaming-15", 15_499_000, 8, 4.6m, 39),
            NewProduct(fashionPria.Id, "Kemeja Flanel Pria", "kemeja-flanel-pria", 189_000, 60, 4.3m, 210),
            NewProduct(fashionPria.Id, "Celana Chino Pria", "celana-chino-pria", 229_000, 45, 4.1m, 95),
            NewProduct(fashionWanita.Id, "Dress Casual Wanita", "dress-casual-wanita", 259_000, 40, 4.4m, 150),
            NewProduct(fashionWanita.Id, "Blouse Wanita", "blouse-wanita", 149_000, 55, 4.0m, 72),
            NewProduct(rumahTangga.Id, "Blender Multifungsi", "blender-multifungsi", 349_000, 30, 4.6m, 66),
            NewProduct(rumahTangga.Id, "Rice Cooker Digital", "rice-cooker-digital", 459_000, 20, 4.5m, 88),
            NewProduct(olahraga.Id, "Sepatu Lari Pro", "sepatu-lari-pro", 599_000, 35, 4.8m, 132),
            NewProduct(olahraga.Id, "Matras Yoga", "matras-yoga", 129_000, 50, 4.3m, 44));

        await dbContext.SaveChangesAsync();
    }

    private static Category NewCategory(string name, string slug, Guid? parentCategoryId = null) => new()
    {
        Id = Guid.NewGuid(),
        Name = name,
        Slug = slug,
        ParentCategoryId = parentCategoryId,
        CreatedAt = DateTime.UtcNow,
    };

    private static Product NewProduct(
        Guid categoryId, string name, string slug, decimal price, int stock, decimal ratingAverage, int ratingCount) => new()
    {
        Id = Guid.NewGuid(),
        CategoryId = categoryId,
        Name = name,
        Slug = slug,
        Description = $"{name} — produk contoh untuk pengembangan Shopy.",
        Price = price,
        Stock = stock,
        RatingAverage = ratingAverage,
        RatingCount = ratingCount,
        IsActive = true,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
    };
}
