class SellerException implements Exception {
  final String message;

  const SellerException(this.message);

  @override
  String toString() => message;
}
