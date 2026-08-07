import '../models/cart/cart_item.dart';

/// Ongkos kirim flat untuk simulasi UI (belum ada integrasi kurir/backend).
const int kMockShippingCost = 15000;

class CartState {
  final List<CartItem> items;
  final String? promoCode;
  final int promoDiscount;

  const CartState({this.items = const [], this.promoCode, this.promoDiscount = 0});

  bool get isEmpty => items.isEmpty;

  bool get allSelected => items.isNotEmpty && items.every((item) => item.selected);

  List<CartItem> get selectedItems => items.where((item) => item.selected).toList();

  int get selectedCount => selectedItems.length;

  /// Total qty semua barang (dipakai untuk badge di bottom nav).
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.qty);

  int get subtotal => selectedItems.fold(0, (sum, item) => sum + item.subtotal);

  int get shippingCost => isEmpty ? 0 : kMockShippingCost;

  int get total => subtotal - promoDiscount + shippingCost;

  bool get hasPromo => promoCode != null;

  CartState copyWith({
    List<CartItem>? items,
    String? promoCode,
    int? promoDiscount,
    bool clearPromo = false,
  }) {
    return CartState(
      items: items ?? this.items,
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      promoDiscount: clearPromo ? 0 : (promoDiscount ?? this.promoDiscount),
    );
  }
}
