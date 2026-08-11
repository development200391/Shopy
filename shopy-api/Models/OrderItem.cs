namespace shopy_api.Models;

public class OrderItem : ISoftDeletable
{
    public Guid Id { get; set; }

    public Guid OrderId { get; set; }
    public Order Order { get; set; } = null!;

    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    // Diisi saat checkout dikelompokkan per toko (Fase 4 TASKSELLER.md) — nullable karena
    // item order lama/pra-refactor tidak punya sub-order.
    public Guid? SubOrderId { get; set; }
    public SubOrder? SubOrder { get; set; }

    // Snapshot nama & harga produk saat order dibuat.
    public string ProductNameSnapshot { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal Subtotal { get; set; }

    public bool IsDeleted { get; set; }
}
