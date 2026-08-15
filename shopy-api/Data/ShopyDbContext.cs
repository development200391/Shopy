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

    // --- Seller (TASKSELLER.md Fase 0) ---
    public DbSet<Store> Stores => Set<Store>();
    public DbSet<StoreAddress> StoreAddresses => Set<StoreAddress>();
    public DbSet<StoreDocument> StoreDocuments => Set<StoreDocument>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<SubOrder> SubOrders => Set<SubOrder>();
    public DbSet<SubOrderStatusHistory> SubOrderStatusHistories => Set<SubOrderStatusHistory>();
    public DbSet<StoreBalance> StoreBalances => Set<StoreBalance>();
    public DbSet<BalanceTransaction> BalanceTransactions => Set<BalanceTransaction>();
    public DbSet<BankAccount> BankAccounts => Set<BankAccount>();
    public DbSet<Withdrawal> Withdrawals => Set<Withdrawal>();
    public DbSet<Voucher> Vouchers => Set<Voucher>();
    public DbSet<VoucherUsage> VoucherUsages => Set<VoucherUsage>();
    public DbSet<FlashSale> FlashSales => Set<FlashSale>();
    public DbSet<FlashSaleItem> FlashSaleItems => Set<FlashSaleItem>();
    public DbSet<ChatRoom> ChatRooms => Set<ChatRoom>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<StoreFollower> StoreFollowers => Set<StoreFollower>();

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
            e.Property(p => p.DiscountPrice).HasPrecision(18, 2);
            e.Property(p => p.Condition).HasConversion<string>().HasMaxLength(20);
            e.HasOne(p => p.Store)
                .WithMany(s => s.Products)
                .HasForeignKey(p => p.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
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
            e.HasOne(r => r.Store)
                .WithMany()
                .HasForeignKey(r => r.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(r => r.SubOrder)
                .WithMany()
                .HasForeignKey(r => r.SubOrderId)
                .OnDelete(DeleteBehavior.Restrict);
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
            e.Property(dt => dt.AppType).HasConversion<string>().HasMaxLength(10);
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
            e.HasOne(n => n.Store)
                .WithMany()
                .HasForeignKey(n => n.StoreId)
                .OnDelete(DeleteBehavior.SetNull);
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
            e.HasOne(oi => oi.SubOrder)
                .WithMany(so => so.OrderItems)
                .HasForeignKey(oi => oi.SubOrderId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // --- Seller (TASKSELLER.md Fase 0) ---

        builder.Entity<Store>(e =>
        {
            e.HasIndex(s => s.OwnerUserId).IsUnique();
            e.HasIndex(s => s.Slug).IsUnique();
            e.Property(s => s.Status).HasConversion<string>().HasMaxLength(20);
            e.Property(s => s.RatingAverage).HasPrecision(3, 2);
            e.HasOne(s => s.OwnerUser)
                .WithMany()
                .HasForeignKey(s => s.OwnerUserId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(s => s.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<StoreAddress>(e =>
        {
            e.HasOne(a => a.Store)
                .WithMany(s => s.Addresses)
                .HasForeignKey(a => a.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<StoreDocument>(e =>
        {
            e.Property(d => d.Type).HasConversion<string>().HasMaxLength(20);
            e.Property(d => d.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(d => d.Store)
                .WithMany(s => s.Documents)
                .HasForeignKey(d => d.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<ProductImage>(e =>
        {
            e.HasOne(pi => pi.Product)
                .WithMany(p => p.Images)
                .HasForeignKey(pi => pi.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<SubOrder>(e =>
        {
            e.HasIndex(so => so.SubOrderNumber).IsUnique();
            e.Property(so => so.Status).HasConversion<string>().HasMaxLength(20);
            e.Property(so => so.Subtotal).HasPrecision(18, 2);
            e.Property(so => so.ShippingCost).HasPrecision(18, 2);
            e.Property(so => so.VoucherDiscount).HasPrecision(18, 2);
            e.Property(so => so.CommissionAmount).HasPrecision(18, 2);
            e.Property(so => so.SellerEarning).HasPrecision(18, 2);
            e.HasOne(so => so.Order)
                .WithMany(o => o.SubOrders)
                .HasForeignKey(so => so.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(so => so.Store)
                .WithMany()
                .HasForeignKey(so => so.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(so => so.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<SubOrderStatusHistory>(e =>
        {
            e.Property(h => h.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(h => h.SubOrder)
                .WithMany(so => so.StatusHistories)
                .HasForeignKey(h => h.SubOrderId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(h => h.ChangedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<StoreBalance>(e =>
        {
            e.HasKey(b => b.StoreId);
            e.Property(b => b.AvailableBalance).HasPrecision(18, 2);
            e.Property(b => b.PendingBalance).HasPrecision(18, 2);
            e.Property(b => b.TotalEarning).HasPrecision(18, 2);
            e.HasOne(b => b.Store)
                .WithOne()
                .HasForeignKey<StoreBalance>(b => b.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<BalanceTransaction>(e =>
        {
            e.Property(t => t.Type).HasConversion<string>().HasMaxLength(20);
            e.Property(t => t.Amount).HasPrecision(18, 2);
            e.Property(t => t.BalanceAfter).HasPrecision(18, 2);
            e.HasOne(t => t.Store)
                .WithMany()
                .HasForeignKey(t => t.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(t => t.SubOrder)
                .WithMany()
                .HasForeignKey(t => t.SubOrderId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(t => t.Withdrawal)
                .WithMany()
                .HasForeignKey(t => t.WithdrawalId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(t => t.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<BankAccount>(e =>
        {
            e.HasOne(a => a.Store)
                .WithMany()
                .HasForeignKey(a => a.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<Withdrawal>(e =>
        {
            e.Property(w => w.Status).HasConversion<string>().HasMaxLength(20);
            e.Property(w => w.Amount).HasPrecision(18, 2);
            e.Property(w => w.AdminFee).HasPrecision(18, 2);
            e.Property(w => w.NetAmount).HasPrecision(18, 2);
            e.HasOne(w => w.Store)
                .WithMany()
                .HasForeignKey(w => w.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(w => w.BankAccount)
                .WithMany()
                .HasForeignKey(w => w.BankAccountId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(w => w.RequestedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<Voucher>(e =>
        {
            e.Property(v => v.Type).HasConversion<string>().HasMaxLength(20);
            e.Property(v => v.Value).HasPrecision(18, 2);
            e.Property(v => v.MaxDiscount).HasPrecision(18, 2);
            e.Property(v => v.MinPurchase).HasPrecision(18, 2);
            e.HasOne(v => v.Store)
                .WithMany()
                .HasForeignKey(v => v.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(v => new { v.StoreId, v.Code })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
        });

        builder.Entity<VoucherUsage>(e =>
        {
            e.Property(u => u.DiscountAmount).HasPrecision(18, 2);
            e.HasOne(u => u.Voucher)
                .WithMany()
                .HasForeignKey(u => u.VoucherId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(u => u.User)
                .WithMany()
                .HasForeignKey(u => u.UserId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(u => u.SubOrder)
                .WithMany()
                .HasForeignKey(u => u.SubOrderId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(u => u.UsedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<FlashSale>(e =>
        {
            e.HasOne(f => f.Store)
                .WithMany()
                .HasForeignKey(f => f.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(f => f.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<FlashSaleItem>(e =>
        {
            e.Property(fi => fi.SpecialPrice).HasPrecision(18, 2);
            e.HasOne(fi => fi.FlashSale)
                .WithMany(f => f.Items)
                .HasForeignKey(fi => fi.FlashSaleId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(fi => fi.Product)
                .WithMany()
                .HasForeignKey(fi => fi.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<ChatRoom>(e =>
        {
            e.HasOne(c => c.Store)
                .WithMany()
                .HasForeignKey(c => c.StoreId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.BuyerUser)
                .WithMany()
                .HasForeignKey(c => c.BuyerUserId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(c => new { c.StoreId, c.BuyerUserId })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
            e.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<ChatMessage>(e =>
        {
            e.Property(m => m.SenderType).HasConversion<string>().HasMaxLength(20);
            e.HasOne(m => m.ChatRoom)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ChatRoomId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(m => m.Product)
                .WithMany()
                .HasForeignKey(m => m.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(m => m.SubOrder)
                .WithMany()
                .HasForeignKey(m => m.SubOrderId)
                .OnDelete(DeleteBehavior.Restrict);
            e.Property(m => m.CreatedAt).HasDefaultValueSql("now()");
        });

        builder.Entity<StoreFollower>(e =>
        {
            e.HasOne(f => f.Store)
                .WithMany()
                .HasForeignKey(f => f.StoreId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(f => f.User)
                .WithMany()
                .HasForeignKey(f => f.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(f => new { f.StoreId, f.UserId })
                .IsUnique()
                .HasFilter("\"IsDeleted\" = false");
            e.Property(f => f.CreatedAt).HasDefaultValueSql("now()");
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
