namespace shopy_api.Models;

public enum SubOrderStatus
{
    WaitingPayment,
    NewOrder,
    Processing,
    Shipped,
    Completed,
    Cancelled,
    Rejected
}
