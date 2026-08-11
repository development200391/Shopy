class StoreException implements Exception {
  final String message;

  const StoreException(this.message);

  @override
  String toString() => message;
}
