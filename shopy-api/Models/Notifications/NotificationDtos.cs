namespace shopy_api.Models.Notifications;

public record NotificationDto(
    Guid Id,
    string Type,
    string Title,
    string Body,
    Guid? OrderId,
    bool IsRead,
    DateTime CreatedAt);

public record BroadcastPromoRequest(string Title, string Body);
