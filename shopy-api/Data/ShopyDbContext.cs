using System.Linq.Expressions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using shopy_api.Models;

namespace shopy_api.Data;

public class ShopyDbContext(DbContextOptions<ShopyDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<PasswordResetCode> PasswordResetCodes => Set<PasswordResetCode>();
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<ApplicationUser>(e =>
        {
            e.Property(u => u.FullName).HasMaxLength(200).IsRequired();
            e.Property(u => u.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Address>(e =>
        {
            e.HasOne(a => a.User)
                .WithMany(u => u.Addresses)
                .HasForeignKey(a => a.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(a => a.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Category>(e =>
        {
            e.HasIndex(c => c.Slug).IsUnique();
            e.HasOne(c => c.ParentCategory)
                .WithMany(c => c.ChildCategories)
                .HasForeignKey(c => c.ParentCategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Product>(e =>
        {
            e.HasIndex(p => p.Slug).IsUnique();
            e.Property(p => p.Price).HasPrecision(18, 2);
            e.Property(p => p.RatingAverage).HasPrecision(3, 2);
            e.HasOne(p => p.Category)
                .WithMany(c => c.Products)
                .HasForeignKey(p => p.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(p => p.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Review>(e =>
        {
            e.HasOne(r => r.Product)
                .WithMany(p => p.Reviews)
                .HasForeignKey(r => r.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(r => r.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            // Satu user hanya bisa punya satu review aktif per produk.
            e.HasIndex(r => new { r.ProductId, r.UserId })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
            e.Property(r => r.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Cart>(e =>
        {
            e.HasOne(c => c.User)
                .WithMany()
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<CartItem>(e =>
        {
            e.HasOne(ci => ci.Cart)
                .WithMany(c => c.CartItems)
                .HasForeignKey(ci => ci.CartId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(ci => ci.Product)
                .WithMany(p => p.CartItems)
                .HasForeignKey(ci => ci.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(ci => new { ci.CartId, ci.ProductId })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
            e.Property(ci => ci.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Order>(e =>
        {
            e.HasIndex(o => o.OrderNumber).IsUnique();
            e.Property(o => o.TotalAmount).HasPrecision(18, 2);
            e.Property(o => o.ShippingCost).HasPrecision(18, 2);
            e.Property(o => o.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(o => o.User)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(o => o.Address)
                .WithMany()
                .HasForeignKey(o => o.AddressId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(o => o.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<OrderStatusHistory>(e =>
        {
            e.Property(h => h.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(h => h.Order)
                .WithMany()
                .HasForeignKey(h => h.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(h => h.ChangedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Payment>(e =>
        {
            e.HasIndex(p => p.MidtransOrderId).IsUnique();
            e.Property(p => p.Method).HasConversion<string>().HasMaxLength(20);
            e.Property(p => p.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(p => p.Order)
                .WithMany()
                .HasForeignKey(p => p.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(p => p.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<DeviceToken>(e =>
        {
            e.HasIndex(dt => dt.Token).IsUnique();
            e.HasOne(dt => dt.User)
                .WithMany()
                .HasForeignKey(dt => dt.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(dt => dt.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Notification>(e =>
        {
            e.Property(n => n.Type).HasConversion<string>().HasMaxLength(20);
            e.HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(n => n.Order)
                .WithMany()
                .HasForeignKey(n => n.OrderId)
                .OnDelete(DeleteBehavior.SetNull);
            e.Property(n => n.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<RefreshToken>(e =>
        {
            e.HasIndex(rt => rt.Token).IsUnique();
            e.HasOne(rt => rt.User)
                .WithMany()
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(rt => rt.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<PasswordResetCode>(e =>
        {
            e.HasOne(prc => prc.User)
                .WithMany()
                .HasForeignKey(prc => prc.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(prc => prc.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<WishlistItem>(e =>
        {
            e.HasOne(w => w.User)
                .WithMany()
                .HasForeignKey(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(w => w.Product)
                .WithMany()
                .HasForeignKey(w => w.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
            // Satu user hanya bisa punya satu entri wishlist aktif per produk.
            e.HasIndex(w => new { w.UserId, w.ProductId })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
            e.Property(w => w.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<OrderItem>(e =>
        {
            e.Property(oi => oi.UnitPrice).HasPrecision(18, 2);
            e.Property(oi => oi.Subtotal).HasPrecision(18, 2);
            e.HasOne(oi => oi.Order)
                .WithMany(o => o.OrderItems)
                .HasForeignKey(oi => oi.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(oi => oi.Product)
                .WithMany(p => p.OrderItems)
                .HasForeignKey(oi => oi.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // Soft delete: sembunyikan baris IsDeleted=true secara default di semua tabel yang mengimplementasi ISoftDeletable.
        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            if (!typeof(ISoftDeletable).IsAssignableFrom(entityType.ClrType))
            {
                continue;
            }

            var parameter = Expression.Parameter(entityType.ClrType, "e");
            var property = Expression.Property(parameter, nameof(ISoftDeletable.IsDeleted));
            var condition = Expression.Lambda(Expression.Equal(property, Expression.Constant(false)), parameter);
            builder.Entity(entityType.ClrType).HasQueryFilter(condition);
        }
    }
}
