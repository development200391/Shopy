class WishlistException implements Exception {
  final String message;

  const WishlistException(this.message);

  @override
  String toString() => message;
}
