class SellerOrderItem {
  final String id;
  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  const SellerOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    return SellerOrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).round(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).round(),
    );
  }
}

class SellerOrderAddress {
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String province;
  final String postalCode;

  const SellerOrderAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  factory SellerOrderAddress.fromJson(Map<String, dynamic> json) {
    return SellerOrderAddress(
      recipientName: json['recipientName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String,
      province: json['province'] as String,
      postalCode: json['postalCode'] as String,
    );
  }
}

class SellerOrderStatusHistoryEntry {
  final String status;
  final String? note;
  final DateTime changedAt;

  const SellerOrderStatusHistoryEntry({required this.status, this.note, required this.changedAt});

  factory SellerOrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SellerOrderStatusHistoryEntry(
      status: json['status'] as String,
      note: json['note'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }
}

class SellerOrderBuyer {
  final String userId;
  final String fullName;
  final int joinedYear;
  final int orderCountAtThisStore;

  const SellerOrderBuyer({
    required this.userId,
    required this.fullName,
    required this.joinedYear,
    required this.orderCountAtThisStore,
  });

  factory SellerOrderBuyer.fromJson(Map<String, dynamic> json) {
    return SellerOrderBuyer(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      joinedYear: json['joinedYear'] as int,
      orderCountAtThisStore: json['orderCountAtThisStore'] as int,
    );
  }
}

class SellerOrderDetail {
  final String id;
  final String subOrderNumber;
  final String status;
  final SellerOrderBuyer buyer;
  final SellerOrderAddress address;
  final List<SellerOrderItem> items;
  final int subtotal;
  final int shippingCost;
  final int commissionAmount;
  final int sellerEarning;
  final int totalAmount;
  final String? courierCode;
  final String? courierService;
  final String? trackingNumber;
  final String? proofPhotoUrl;
  final String? note;
  final String? cancelReason;
  final DateTime? autoCancelAt;
  final List<SellerOrderStatusHistoryEntry> statusHistory;
  final DateTime createdAt;

  const SellerOrderDetail({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    required this.buyer,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.commissionAmount,
    required this.sellerEarning,
    required this.totalAmount,
    this.courierCode,
    this.courierService,
    this.trackingNumber,
    this.proofPhotoUrl,
    this.note,
    this.cancelReason,
    this.autoCancelAt,
    required this.statusHistory,
    required this.createdAt,
  });

  factory SellerOrderDetail.fromJson(Map<String, dynamic> json) {
    return SellerOrderDetail(
      id: json['id'] as String,
      subOrderNumber: json['subOrderNumber'] as String,
      status: json['status'] as String,
      buyer: SellerOrderBuyer.fromJson(json['buyer'] as Map<String, dynamic>),
      address: SellerOrderAddress.fromJson(json['address'] as Map<String, dynamic>),
      items: (json['items'] as List)
          .map((e) => SellerOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).round(),
      shippingCost: (json['shippingCost'] as num).round(),
      commissionAmount: (json['commissionAmount'] as num).round(),
      sellerEarning: (json['sellerEarning'] as num).round(),
      totalAmount: (json['totalAmount'] as num).round(),
      courierCode: json['courierCode'] as String?,
      courierService: json['courierService'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      proofPhotoUrl: json['proofPhotoUrl'] as String?,
      note: json['note'] as String?,
      cancelReason: json['cancelReason'] as String?,
      autoCancelAt: json['autoCancelAt'] == null ? null : DateTime.parse(json['autoCancelAt'] as String),
      statusHistory: (json['statusHistory'] as List)
          .map((e) => SellerOrderStatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
