class ChatRoom {
  final String id;
  final String storeId;
  final String storeName;
  final String? storeLogoUrl;
  final String buyerUserId;
  final String buyerName;
  final String? buyerAvatarUrl;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  const ChatRoom({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeLogoUrl,
    required this.buyerUserId,
    required this.buyerName,
    this.buyerAvatarUrl,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      storeId: json['storeId'] as String,
      storeName: json['storeName'] as String,
      storeLogoUrl: json['storeLogoUrl'] as String?,
      buyerUserId: json['buyerUserId'] as String,
      buyerName: json['buyerName'] as String,
      buyerAvatarUrl: json['buyerAvatarUrl'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageAt: json['lastMessageAt'] == null ? null : DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
