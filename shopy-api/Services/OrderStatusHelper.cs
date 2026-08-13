using shopy_api.Models;

namespace shopy_api.Services;

/// <summary>
/// Menghitung status agregat <see cref="Order"/> dari kumpulan status <see cref="SubOrder"/>
/// miliknya. Dipanggil ulang setiap kali ada transisi status sub-order (payment, seller
/// accept/reject/ship, buyer cancel/complete, auto-transition).
/// </summary>
public static class OrderStatusHelper
{
    public static OrderStatus Recalculate(IEnumerable<SubOrderStatus> subOrderStatuses)
    {
        var statuses = subOrderStatuses.ToList();
        if (statuses.Count == 0)
        {
            return OrderStatus.Pending;
        }

        if (statuses.Any(s => s == SubOrderStatus.WaitingPayment))
        {
            return OrderStatus.Pending;
        }

        var activeStatuses = statuses.Where(s => s is not (SubOrderStatus.Cancelled or SubOrderStatus.Rejected)).ToList();
        if (activeStatuses.Count == 0)
        {
            return OrderStatus.Cancelled;
        }

        if (activeStatuses.All(s => s == SubOrderStatus.Completed))
        {
            return OrderStatus.Completed;
        }

        if (activeStatuses.All(s => s is SubOrderStatus.Shipped or SubOrderStatus.Completed))
        {
            return OrderStatus.Shipped;
        }

        return OrderStatus.Processing;
    }
}
