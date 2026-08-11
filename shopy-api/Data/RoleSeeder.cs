using Microsoft.AspNetCore.Identity;

namespace shopy_api.Data;

// Role dasar aplikasi (TASKSELLER.md Fase 1). Beda dari CatalogSeeder — ini harus jalan di
// SEMUA environment (termasuk production), bukan cuma dev, karena role wajib ada supaya
// [Authorize(Roles = "...")] bisa dipakai controller seller/admin.
public static class RoleSeeder
{
    private static readonly string[] Roles = ["Buyer", "Seller", "Admin"];

    public static async Task SeedAsync(RoleManager<IdentityRole<Guid>> roleManager)
    {
        foreach (var role in Roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<Guid>(role));
            }
        }
    }
}
