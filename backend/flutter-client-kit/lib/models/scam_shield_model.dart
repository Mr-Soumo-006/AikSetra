class ScamShieldResult {
  final int riskScore;
  final String riskLevel; // 'SAFE', 'LOW', 'MODERATE', 'HIGH'
  final List<String> warnings;
  final String recommendation; // 'PROCEED', 'WARN_USER', 'REQUIRE_COOLING_OFF', 'BLOCK'
  final String verifiedLegalName;
  final bool coolingOffRequired;
  final int coolingOffSeconds;
  final bool isBlacklisted;

  ScamShieldResult({
    required this.riskScore,
    required this.riskLevel,
    required this.warnings,
    required this.recommendation,
    required this.verifiedLegalName,
    required this.coolingOffRequired,
    required this.coolingOffSeconds,
    required this.isBlacklisted,
  });

  factory ScamShieldResult.fromJson(Map<String, dynamic> json) {
    final signals = json['signals'] as Map<String, dynamic>? ?? {};
    final warningsRaw = json['warnings'] as List<dynamic>? ?? [];

    return ScamShieldResult(
      riskScore: json['riskScore'] ?? 0,
      riskLevel: json['riskLevel'] ?? 'SAFE',
      warnings: warningsRaw.map((e) => e.toString()).toList(),
      recommendation: json['recommendation'] ?? 'PROCEED',
      verifiedLegalName: json['verifiedLegalName'] ?? '',
      coolingOffRequired: signals['coolingOffRequired'] ?? false,
      coolingOffSeconds: signals['coolingOffSeconds'] ?? 0,
      isBlacklisted: signals['blacklisted'] ?? false,
    );
  }
}
