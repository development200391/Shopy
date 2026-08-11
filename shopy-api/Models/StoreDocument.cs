namespace shopy_api.Models;

public class StoreDocument : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public StoreDocumentType Type { get; set; }
    public string FileUrl { get; set; } = string.Empty;

    public DocumentReviewStatus Status { get; set; } = DocumentReviewStatus.Pending;
    public string? RejectReason { get; set; }
    public DateTime? ReviewedAt { get; set; }

    public bool IsDeleted { get; set; }
}
