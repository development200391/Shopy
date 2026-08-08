/// Urutan produk, sesuai enum `ProductSort` di backend — dikirim sebagai
/// nama enum-nya lewat query string (mis. `sort=PriceAsc`).
enum ProductSort {
  newest('Newest', 'Terbaru'),
  priceAsc('PriceAsc', 'Harga Terendah'),
  priceDesc('PriceDesc', 'Harga Tertinggi'),
  ratingDesc('RatingDesc', 'Rating Tertinggi');

  final String queryValue;
  final String label;

  const ProductSort(this.queryValue, this.label);
}
