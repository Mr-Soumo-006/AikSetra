class UserModel {
  final String id;
  final String phone;
  final String fullName;
  final String email;
  final String primaryVpa;
  final double liteBalance;
  final double lrsUsedUsd;

  UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.primaryVpa,
    required this.liteBalance,
    required this.lrsUsedUsd,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      primaryVpa: json['primaryVpa'] ?? '',
      liteBalance: (json['liteBalance'] as num?)?.toDouble() ?? 0.0,
      lrsUsedUsd: (json['lrsUsedUsd'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BankAccountModel {
  final String id;
  final String bankName;
  final String bankCode;
  final String ifsc;
  final String maskedAccountNumber;
  final double balance;
  final bool isPrimary;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.bankCode,
    required this.ifsc,
    required this.maskedAccountNumber,
    required this.balance,
    required this.isPrimary,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] ?? '',
      bankName: json['bankName'] ?? '',
      bankCode: json['bankCode'] ?? '',
      ifsc: json['ifsc'] ?? '',
      maskedAccountNumber: json['maskedAccountNumber'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}
