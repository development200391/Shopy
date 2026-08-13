class ChatProductAttachment {
  final String id;
  final String name;
  final String? imageUrl;
  final int price;
  final int stock;

  const ChatProductAttachment({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stock,
  });

  factory ChatProductAttachment.fromJson(Map<String, dynamic> json) {
    return ChatProductAttachment(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num).round(),
      stock: json['stock'] as int,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderType;
  final bool isMine;
  final String? body;
  final String? attachmentUrl;
  final ChatProductAttachment? product;
  final String? subOrderNumber;
  final DateTime? readAt;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.isMine,
    this.body,
    this.attachmentUrl,
    this.product,
    this.subOrderNumber,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderType: json['senderType'] as String,
      isMine: json['isMine'] as bool,
      body: json['body'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      product: json['product'] == null
          ? null
          : ChatProductAttachment.fromJson(json['product'] as Map<String, dynamic>),
      subOrderNumber: json['subOrderNumber'] as String?,
      readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
