namespace shopy_api.Services;

public interface IPushNotificationService
{
    bool IsConfigured { get; }

    Task SendAsync(IReadOnlyList<string> tokens, string title, string body, IReadOnlyDictionary<string, string>? data = null);
}
