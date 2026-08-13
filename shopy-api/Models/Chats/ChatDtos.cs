namespace shopy_api.Models.Chats;

public record ChatRoomDto(
    Guid Id,
    Guid StoreId,
    string StoreName,
    string? StoreLogoUrl,
    Guid BuyerUserId,
    string BuyerName,
    string? BuyerAvatarUrl,
    string? LastMessagePreview,
    DateTime? LastMessageAt,
    int UnreadCount,
    DateTime CreatedAt);

public record ChatProductAttachmentDto(Guid Id, string Name, string? ImageUrl, decimal Price, int Stock);

public record ChatMessageDto(
    Guid Id,
    string SenderType,
    bool IsMine,
    string? Body,
    string? AttachmentUrl,
    ChatProductAttachmentDto? Product,
    string? SubOrderNumber,
    DateTime? ReadAt,
    DateTime CreatedAt);

public record OpenChatRoomRequest(Guid StoreId);

public record SendChatMessageRequest(string? Body, string? AttachmentUrl, Guid? ProductId, Guid? SubOrderId);
