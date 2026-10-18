class ProtectedPayEscrowModel {
  final String id;
  final String buyerUserId;
  final String sellerVpa;
  final String sellerName;
  final double amount;
  final String itemDescription;
  final String status; // 'HELD_IN_ESCROW', 'RELEASED_TO_SELLER', 'DISPUTED', 'REFUNDED_TO_BUYER'
  final DateTime expiresAt;
  final String? trackingNumber;
  final String? disputeReason;

  ProtectedPayEscrowModel({
    required this.id,
    required this.buyerUserId,
    required this.sellerVpa,
    required this.sellerName,
    required this.amount,
    required this.itemDescription,
    required this.status,
    required this.expiresAt,
    this.trackingNumber,
    this.disputeReason,
  });

  factory ProtectedPayEscrowModel.fromJson(Map<String, dynamic> json) {
    return ProtectedPayEscrowModel(
      id: json['id'] ?? '',
      buyerUserId: json['buyerUserId'] ?? '',
      sellerVpa: json['sellerVpa'] ?? '',
      sellerName: json['sellerName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      itemDescription: json['itemDescription'] ?? '',
      status: json['status'] ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '') ?? DateTime.now(),
      trackingNumber: json['trackingNumber'],
      disputeReason: json['disputeReason'],
    );
  }
}
