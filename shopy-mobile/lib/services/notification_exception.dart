class NotificationException implements Exception {
  final String message;

  const NotificationException(this.message);

  @override
  String toString() => message;
}
