class CatalogException implements Exception {
  final String message;

  const CatalogException(this.message);

  @override
  String toString() => message;
}
