using shopy_api.Models;

namespace shopy_api.Services;

public interface INotificationService
{
    Task NotifyOrderStatusChangedAsync(Order order);

    Task<int> BroadcastPromoAsync(string title, string body);
}
