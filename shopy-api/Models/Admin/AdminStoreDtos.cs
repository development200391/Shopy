namespace shopy_api.Models.Admin;

public record AdminStoreListItemDto(
    Guid Id,
    string Name,
    string Slug,
    string OwnerName,
    string OwnerEmail,
    string Status,
    string? ModerationReason,
    int ProductCount,
    DateTime CreatedAt);

public record RejectStoreRequest(string Reason);

public record SuspendStoreRequest(string? Reason);
