using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using shopy_api.Data;
using shopy_api.Models;

namespace shopy_api.Services;

public class TokenService(
    IConfiguration configuration,
    UserManager<ApplicationUser> userManager,
    ShopyDbContext dbContext) : ITokenService
{
    private readonly IConfiguration _configuration = configuration;

    public async Task<AccessTokenResult> GenerateAccessTokenAsync(ApplicationUser user)
    {
        var jwtSection = _configuration.GetSection("Jwt");
        var key = jwtSection["Key"]
            ?? throw new InvalidOperationException("Jwt:Key belum dikonfigurasi.");
        var issuer = jwtSection["Issuer"];
        var audience = jwtSection["Audience"];
        var expiryMinutes = jwtSection.GetValue("AccessTokenExpiryMinutes", 15);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("full_name", user.FullName),
        };

        // Claim type "role" (bukan ClaimTypes.Role) — inbound claim type mapping bawaan JWT
        // bearer otomatis convert ini ke ClaimTypes.Role saat validasi, supaya
        // [Authorize(Roles = "...")] & User.IsInRole() bekerja (lihat TASKSELLER.md Fase 1).
        var roles = await userManager.GetRolesAsync(user);
        claims.AddRange(roles.Select(role => new Claim("role", role)));

        var storeId = await dbContext.Stores
            .Where(s => s.OwnerUserId == user.Id)
            .Select(s => (Guid?)s.Id)
            .FirstOrDefaultAsync();
        if (storeId is not null)
        {
            claims.Add(new Claim("store_id", storeId.Value.ToString()));
        }

        var signingKey = new SymmetricSecurityKey(Convert.FromBase64String(key));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var expiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return new AccessTokenResult(new JwtSecurityTokenHandler().WriteToken(token), expiresAt);
    }

    public string GenerateRefreshToken()
    {
        return Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    }

    public DateTime GetRefreshTokenExpiry()
    {
        var days = _configuration.GetValue("Jwt:RefreshTokenExpiryDays", 7);
        return DateTime.UtcNow.AddDays(days);
    }
}
