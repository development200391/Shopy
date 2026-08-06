using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Models.Auth;
using shopy_api.Services;

namespace shopy_api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    UserManager<ApplicationUser> userManager,
    ITokenService tokenService,
    IEmailSender emailSender,
    IFacebookAuthService facebookAuthService,
    IConfiguration configuration,
    ILogger<AuthController> logger,
    IHostEnvironment hostEnvironment,
    ShopyDbContext dbContext) : ControllerBase
{
    private const int ResetCodeExpiryMinutes = 10;

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request)
    {
        var existing = await userManager.FindByEmailAsync(request.Email);
        if (existing is not null)
        {
            return Conflict(new { message = "Email sudah terdaftar." });
        }

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            FullName = request.FullName,
            PhoneNumber = request.PhoneNumber,
            CreatedAt = DateTime.UtcNow,
        };

        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        return await IssueAuthResponseAsync(user);
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
    {
        var user = await userManager.FindByEmailAsync(request.Email);
        if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
        {
            return Unauthorized(new { message = "Email atau password salah." });
        }

        return await IssueAuthResponseAsync(user);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh(RefreshRequest request)
    {
        var storedToken = await dbContext.RefreshTokens
            .Include(rt => rt.User)
            .SingleOrDefaultAsync(rt => rt.Token == request.RefreshToken);

        if (storedToken is null || !storedToken.IsActive)
        {
            return Unauthorized(new { message = "Refresh token tidak valid atau sudah kedaluwarsa." });
        }

        storedToken.RevokedAt = DateTime.UtcNow;

        return await IssueAuthResponseAsync(storedToken.User);
    }

    [Authorize]
    [HttpGet("me")]
    public IActionResult Me()
    {
        return Ok(new
        {
            userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub"),
            email = User.FindFirstValue(ClaimTypes.Email),
            fullName = User.FindFirstValue("full_name"),
        });
    }

    [HttpPost("external/google")]
    public async Task<ActionResult<AuthResponse>> GoogleLogin(GoogleLoginRequest request)
    {
        var clientId = configuration["Authentication:Google:ClientId"];
        if (string.IsNullOrEmpty(clientId))
        {
            return Problem("Login Google belum dikonfigurasi di server.", statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(request.IdToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = [clientId],
            });
        }
        catch (InvalidJwtException)
        {
            return Unauthorized(new { message = "Token Google tidak valid." });
        }

        var user = await FindOrCreateExternalUserAsync("Google", payload.Subject, payload.Email, payload.Name);
        return await IssueAuthResponseAsync(user);
    }

    [HttpPost("external/facebook")]
    public async Task<ActionResult<AuthResponse>> FacebookLogin(FacebookLoginRequest request)
    {
        var appId = configuration["Authentication:Facebook:AppId"];
        if (string.IsNullOrEmpty(appId))
        {
            return Problem("Login Facebook belum dikonfigurasi di server.", statusCode: StatusCodes.Status503ServiceUnavailable);
        }

        FacebookProfile profile;
        try
        {
            profile = await facebookAuthService.VerifyAccessTokenAsync(request.AccessToken);
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { message = "Token Facebook tidak valid." });
        }

        if (string.IsNullOrEmpty(profile.Email))
        {
            return BadRequest(new { message = "Akun Facebook ini tidak punya email publik. Tidak bisa dipakai untuk login." });
        }

        var user = await FindOrCreateExternalUserAsync("Facebook", profile.Id, profile.Email, profile.Name);
        return await IssueAuthResponseAsync(user);
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest request)
    {
        var user = await userManager.FindByEmailAsync(request.Email);
        if (user is not null)
        {
            var code = RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");

            dbContext.PasswordResetCodes.Add(new PasswordResetCode
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                CodeHash = HashCode(code),
                ExpiresAt = DateTime.UtcNow.AddMinutes(ResetCodeExpiryMinutes),
                CreatedAt = DateTime.UtcNow,
            });
            await dbContext.SaveChangesAsync();

            if (hostEnvironment.IsDevelopment())
            {
                // Stand-in supaya alur OTP tetap bisa ditest sebelum provider email asli terpasang.
                logger.LogInformation("[DEV] Kode reset password untuk {Email}: {Code}", request.Email, code);
            }

            try
            {
                await emailSender.SendAsync(
                    user.Email!,
                    "Kode reset password Shopy",
                    $"Kode OTP kamu: {code}\nBerlaku {ResetCodeExpiryMinutes} menit. Jangan bagikan kode ini ke siapa pun.");
            }
            catch (Exception ex)
            {
                // Gagal kirim email tidak boleh bocor ke client (juga tidak boleh membocorkan
                // apakah email terdaftar), cukup dicatat di log server.
                logger.LogError(ex, "Gagal mengirim email reset password ke {Email}", request.Email);
            }
        }

        // Selalu balas sukses generik, supaya endpoint ini tidak bisa dipakai untuk enumerasi email terdaftar.
        return Ok(new { message = "Jika email terdaftar, kode reset sudah dikirim." });
    }

    [HttpPost("verify-reset-code")]
    public async Task<IActionResult> VerifyResetCode(VerifyResetCodeRequest request)
    {
        var isValid = await FindActiveResetCodeAsync(request.Email, request.Code) is not null;
        return Ok(new { valid = isValid });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest request)
    {
        var resetCode = await FindActiveResetCodeAsync(request.Email, request.Code);
        if (resetCode is null)
        {
            return BadRequest(new { message = "Kode reset tidak valid atau sudah kedaluwarsa." });
        }

        var user = await userManager.FindByIdAsync(resetCode.UserId.ToString());
        if (user is null)
        {
            return BadRequest(new { message = "Kode reset tidak valid atau sudah kedaluwarsa." });
        }

        await userManager.RemovePasswordAsync(user);
        var result = await userManager.AddPasswordAsync(user, request.NewPassword);
        if (!result.Succeeded)
        {
            return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
        }

        resetCode.UsedAt = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return Ok(new { message = "Password berhasil diubah." });
    }

    private async Task<PasswordResetCode?> FindActiveResetCodeAsync(string email, string code)
    {
        var user = await userManager.FindByEmailAsync(email);
        if (user is null)
        {
            return null;
        }

        var codeHash = HashCode(code);
        var now = DateTime.UtcNow;
        return await dbContext.PasswordResetCodes
            .Where(prc => prc.UserId == user.Id
                && prc.CodeHash == codeHash
                && prc.UsedAt == null
                && prc.ExpiresAt > now)
            .OrderByDescending(prc => prc.CreatedAt)
            .FirstOrDefaultAsync();
    }

    private async Task<ApplicationUser> FindOrCreateExternalUserAsync(
        string provider, string providerKey, string? email, string? fullName)
    {
        var existingByLogin = await userManager.FindByLoginAsync(provider, providerKey);
        if (existingByLogin is not null)
        {
            return existingByLogin;
        }

        ApplicationUser user;
        var existingByEmail = string.IsNullOrEmpty(email) ? null : await userManager.FindByEmailAsync(email);
        if (existingByEmail is not null)
        {
            user = existingByEmail;
        }
        else
        {
            user = new ApplicationUser
            {
                UserName = email ?? $"{provider.ToLowerInvariant()}_{providerKey}",
                Email = email,
                FullName = fullName ?? string.Empty,
                CreatedAt = DateTime.UtcNow,
            };

            var createResult = await userManager.CreateAsync(user);
            if (!createResult.Succeeded)
            {
                throw new InvalidOperationException(
                    $"Gagal membuat user dari login {provider}: "
                    + string.Join(", ", createResult.Errors.Select(e => e.Description)));
            }
        }

        await userManager.AddLoginAsync(user, new UserLoginInfo(provider, providerKey, provider));
        return user;
    }

    private async Task<AuthResponse> IssueAuthResponseAsync(ApplicationUser user)
    {
        var accessToken = tokenService.GenerateAccessToken(user);
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

        return new AuthResponse(
            accessToken.Token,
            accessToken.ExpiresAt,
            refreshToken.Token,
            user.Id,
            user.Email ?? string.Empty,
            user.FullName);
    }

    private static string HashCode(string code)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(code));
        return Convert.ToHexString(bytes);
    }
}
