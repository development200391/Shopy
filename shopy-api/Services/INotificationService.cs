using shopy_api.Models;

namespace shopy_api.Services;

public interface INotificationService
{
    Task NotifySubOrderStatusChangedAsync(SubOrder subOrder, Store store);

    Task<int> BroadcastPromoAsync(string title, string body);
}
