namespace shopy_api.Models;

public class ChatMessage : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid ChatRoomId { get; set; }
    public ChatRoom ChatRoom { get; set; } = null!;

    public ChatSenderType SenderType { get; set; }
    public Guid SenderUserId { get; set; }

    public string? Body { get; set; }
    public string? AttachmentUrl { get; set; }

    public Guid? ProductId { get; set; }
    public Product? Product { get; set; }

    public Guid? SubOrderId { get; set; }
    public SubOrder? SubOrder { get; set; }

    public DateTime? ReadAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsDeleted { get; set; }
}
