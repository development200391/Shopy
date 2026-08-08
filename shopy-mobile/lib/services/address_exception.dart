class AddressException implements Exception {
  final String message;

  const AddressException(this.message);

  @override
  String toString() => message;
}
