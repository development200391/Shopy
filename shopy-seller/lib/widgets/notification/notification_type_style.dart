import 'package:flutter/material.dart';

import '../../models/notification/notification_type.dart';
import '../../theme/app_colors.dart';

/// Ikon & warna per jenis notifikasi seller — dipakai identik oleh
/// `NotificationBannerHost` (banner foreground) & `NotificationHistoryScreen`
/// (kartu riwayat) supaya konsisten.
(IconData, Color) notificationTypeStyle(NotificationType type) {
  return switch (type) {
    NotificationType.newOrder => (Icons.receipt_long, AppColors.primary),
    NotificationType.paymentReceived => (Icons.payments, AppColors.success),
    NotificationType.lowStock => (Icons.error_outline, AppColors.warning),
    NotificationType.newReview => (Icons.star, AppColors.warning),
    NotificationType.newChat => (Icons.chat_bubble, AppColors.primary),
    NotificationType.withdrawal => (Icons.account_balance, AppColors.success),
    NotificationType.voucherQuota => (Icons.local_offer, AppColors.secondary),
    NotificationType.orderStatus => (Icons.shopping_bag, AppColors.primary),
    NotificationType.promo => (Icons.campaign, AppColors.secondary),
  };
}

(IconData, Color) notificationTypeStyleFromApiValue(String? apiValue) {
  return notificationTypeStyle(NotificationType.fromApiValue(apiValue ?? ''));
}
