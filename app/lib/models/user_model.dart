class UserModel {
  final String id;
  final String phone;
  final String fullName;
  final String email;
  final String primaryVpa;
  final double liteBalance;
  final double lrsUsedUsd;
  final String? dateOfBirth;
  final String? profilePicture;

  UserModel({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.email,
    required this.primaryVpa,
    required this.liteBalance,
    required this.lrsUsedUsd,
    this.dateOfBirth,
    this.profilePicture,
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
      dateOfBirth: json['dateOfBirth'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'email': email,
      'primaryVpa': primaryVpa,
      'liteBalance': liteBalance,
      'lrsUsedUsd': lrsUsedUsd,
      'dateOfBirth': dateOfBirth,
      'profilePicture': profilePicture,
    };
  }

  UserModel copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? email,
    String? primaryVpa,
    double? liteBalance,
    double? lrsUsedUsd,
    String? dateOfBirth,
    String? profilePicture,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      primaryVpa: primaryVpa ?? this.primaryVpa,
      liteBalance: liteBalance ?? this.liteBalance,
      lrsUsedUsd: lrsUsedUsd ?? this.lrsUsedUsd,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profilePicture: profilePicture ?? this.profilePicture,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'bankCode': bankCode,
      'ifsc': ifsc,
      'maskedAccountNumber': maskedAccountNumber,
      'balance': balance,
      'isPrimary': isPrimary,
    };
  }
}
