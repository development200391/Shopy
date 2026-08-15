import 'notification_type.dart';

/// Satu notifikasi milik user, sesuai `NotificationDto` di backend. Dinamai
/// `AppNotification` (bukan `Notification`) supaya tidak bentrok dengan
/// `Notification` bawaan Flutter (`package:flutter/widgets.dart`).
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromApiValue(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      orderId: json['orderId'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
