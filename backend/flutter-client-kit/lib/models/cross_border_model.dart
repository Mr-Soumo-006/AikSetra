class CrossBorderQuoteModel {
  final String quoteId;
  final String targetCurrency;
  final double targetAmount;
  final double sourceAmountInr;
  final double exchangeRate;
  final double marketReferenceRate;
  final double adBankFeeInr;
  final double gstInr;
  final double totalCostInr;
  final String corridorType;
  final String partnerRail;
  final DateTime rateLockExpiresAt;
  final double lrsLimitRemainingUsd;

  CrossBorderQuoteModel({
    required this.quoteId,
    required this.targetCurrency,
    required this.targetAmount,
    required this.sourceAmountInr,
    required this.exchangeRate,
    required this.marketReferenceRate,
    required this.adBankFeeInr,
    required this.gstInr,
    required this.totalCostInr,
    required this.corridorType,
    required this.partnerRail,
    required this.rateLockExpiresAt,
    required this.lrsLimitRemainingUsd,
  });

  factory CrossBorderQuoteModel.fromJson(Map<String, dynamic> json) {
    return CrossBorderQuoteModel(
      quoteId: json['quoteId'] ?? '',
      targetCurrency: json['targetCurrency'] ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      sourceAmountInr: (json['sourceAmountInr'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 0.0,
      marketReferenceRate: (json['marketReferenceRate'] as num?)?.toDouble() ?? 0.0,
      adBankFeeInr: (json['adBankFeeInr'] as num?)?.toDouble() ?? 0.0,
      gstInr: (json['gstInr'] as num?)?.toDouble() ?? 0.0,
      totalCostInr: (json['totalCostInr'] as num?)?.toDouble() ?? 0.0,
      corridorType: json['corridorType'] ?? '',
      partnerRail: json['partnerRail'] ?? '',
      rateLockExpiresAt: DateTime.tryParse(json['rateLockExpiresAt'] ?? '') ?? DateTime.now(),
      lrsLimitRemainingUsd: (json['lrsLimitRemainingUsd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
