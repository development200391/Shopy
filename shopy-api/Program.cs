using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using shopy_api.Data;
using shopy_api.Models;
using shopy_api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers()
    // Supaya enum di body request (mis. UpdateOrderStatusRequest.Status) bisa dikirim
    // sebagai nama string ("Processing"), bukan cuma angka index-nya.
    .AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();
});

builder.Services.AddDbContext<ShopyDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services
    .AddIdentityCore<ApplicationUser>(options =>
    {
        options.Password.RequiredLength = 8;
        options.Password.RequireNonAlphanumeric = false;
        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole<Guid>>()
    .AddEntityFrameworkStores<ShopyDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();
builder.Services.AddScoped<IFacebookAuthService, FacebookAuthService>();
builder.Services.AddScoped<IMidtransService, MidtransService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
// Singleton karena FirebaseApp cuma boleh dibuat sekali per proses.
builder.Services.AddSingleton<IPushNotificationService, PushNotificationService>();
builder.Services.AddHttpClient();

var jwtSection = builder.Configuration.GetSection("Jwt");
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var key = jwtSection["Key"];
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtSection["Issuer"],
            ValidateAudience = true,
            ValidAudience = jwtSection["Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = string.IsNullOrEmpty(key)
                ? null
                : new SymmetricSecurityKey(Convert.FromBase64String(key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json", "Shopy API v1");
        options.RoutePrefix = "swagger";
        options.EnablePersistAuthorization();
    });

    using var seedScope = app.Services.CreateScope();
    await CatalogSeeder.SeedAsync(
        seedScope.ServiceProvider.GetRequiredService<ShopyDbContext>(),
        seedScope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>());
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

internal sealed class BearerSecuritySchemeTransformer(IAuthenticationSchemeProvider authenticationSchemeProvider)
    : IOpenApiDocumentTransformer
{
    public async Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        var schemes = await authenticationSchemeProvider.GetAllSchemesAsync();
        if (!schemes.Any(scheme => scheme.Name == JwtBearerDefaults.AuthenticationScheme))
        {
            return;
        }

        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
        document.Components.SecuritySchemes[JwtBearerDefaults.AuthenticationScheme] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "Masukkan access token hasil login (tanpa kata 'Bearer').",
        };

        var securityRequirement = new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference(JwtBearerDefaults.AuthenticationScheme, document)] = [],
        };

        foreach (var operation in document.Paths.Values.SelectMany(path => path.Operations.Values))
        {
            operation.Security ??= [];
            operation.Security.Add(securityRequirement);
        }
    }
}
