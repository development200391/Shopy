namespace shopy_api.Models;

public class ChatRoom : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid StoreId { get; set; }
    public Store Store { get; set; } = null!;

    public Guid BuyerUserId { get; set; }
    public ApplicationUser BuyerUser { get; set; } = null!;

    public DateTime? LastMessageAt { get; set; }
    public string? LastMessagePreview { get; set; }
    public int UnreadCountSeller { get; set; }
    public int UnreadCountBuyer { get; set; }

    public ICollection<ChatMessage> Messages { get; set; } = [];

    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
