namespace shopy_api.Models;

public class Review : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    // Diisi begitu ReviewsController & alur ulasan per-toko dibuat (Fase 7 TASKSELLER.md).
    public Guid? StoreId { get; set; }
    public Store? Store { get; set; }
    public Guid? SubOrderId { get; set; }
    public SubOrder? SubOrder { get; set; }

    public int Rating { get; set; }
    public string? Comment { get; set; }
    // JSON array string URL gambar ulasan, mis. ["url1","url2"] — cukup 1 kolom, belum perlu tabel terpisah.
    public string? ImageUrls { get; set; }

    public string? SellerReply { get; set; }
    public DateTime? SellerRepliedAt { get; set; }

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
