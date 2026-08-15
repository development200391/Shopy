using Microsoft.AspNetCore.Identity;
using shopy_api.Models;

namespace shopy_api.Data;

// Akun admin demo dev-only, dipakai buat uji endpoint api/admin/* lewat Swagger
// (TASKSELLER.md Fase 9 — "cukup lewat Swagger + akun admin yang di-seed", tidak ada
// dashboard admin). Pola sama seperti CatalogSeeder.EnsureDemoStoreAsync: password
// hardcode di sini seperti akun test@shopy.com/seller-demo@shopy.com, BUKAN untuk
// dipakai di production (seeder ini cuma jalan saat Environment.IsDevelopment()).
public static class AdminSeeder
{
    private const string DemoAdminEmail = "admin-demo@shopy.com";
    private const string DemoAdminPassword = "AdminDemo1234!";

    public static async Task SeedAsync(UserManager<ApplicationUser> userManager)
    {
        var existing = await userManager.FindByEmailAsync(DemoAdminEmail);
        if (existing is not null)
        {
            return;
        }

        var admin = new ApplicationUser
        {
            UserName = DemoAdminEmail,
            Email = DemoAdminEmail,
            FullName = "Admin Demo Shopy",
            CreatedAt = DateTime.UtcNow,
        };
        var result = await userManager.CreateAsync(admin, DemoAdminPassword);
        if (!result.Succeeded)
        {
            throw new InvalidOperationException(
                $"Gagal membuat akun admin demo: {string.Join(", ", result.Errors.Select(e => e.Description))}");
        }

        await userManager.AddToRoleAsync(admin, "Admin");
    }
}
