/// Item di dalam pesanan, sesuai `OrderItemDto` di backend — sudah snapshot
/// nama & harga produk saat pesanan dibuat (tidak berubah walau produk asli berubah).
class OrderLineItem {
  final String id;
  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  const OrderLineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).round(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).round(),
    );
  }
}
