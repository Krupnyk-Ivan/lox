class Order {
  final int? id;
  final int advertisementId;
  final int buyerId;
  final int sellerId;
  final int? receiverId;
  final double finalPrice;
  final DateTime? purchaseDate;
  final String orderStatus;

  Order({
    this.id,
    required this.advertisementId,
    required this.buyerId,
    required this.sellerId,
    this.receiverId,
    required this.finalPrice,
    this.purchaseDate,
    required this.orderStatus,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      advertisementId: json['advertisementId'],
      buyerId: json['buyerId'],
      sellerId: json['sellerId'],
      receiverId: json['receiverId'],
      finalPrice:
          json['finalPrice'] is int
              ? (json['finalPrice'] as int).toDouble()
              : json['finalPrice'] as double,
      purchaseDate:
          json['purchaseDate'] != null
              ? DateTime.parse(json['purchaseDate'])
              : null,
      // Default to 'Pending' if orderStatus is null or not found
      orderStatus: json['orderStatus'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'advertisementId': advertisementId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'finalPrice': finalPrice,
      'orderStatus': orderStatus, // Use the provided or default status
    };

    if (receiverId != null) {
      data['receiverId'] = receiverId;
    }

    return data;
  }
}
