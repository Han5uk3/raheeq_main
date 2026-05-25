class User {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String countryCode;
  final String email;
  final String? avatarUrl;
  final String gender;
  final double walletBalance;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.countryCode,
    required this.email,
    this.avatarUrl,
    required this.gender,
    this.walletBalance = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    double balance = 0.0;
    if (json['wallet'] != null && json['wallet']['balance'] != null) {
      balance = (json['wallet']['balance'] as num).toDouble();
    } else if (json['walletBalance'] != null) {
      balance = (json['walletBalance'] as num).toDouble();
    }

    return User(
      id: json['id'] as String,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      countryCode: json['countryCode'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] ?? 'MALE',
      walletBalance: balance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'email': email,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'wallet': {
        'balance': walletBalance,
      },
    };
  }

  String get fullName => '$firstName $lastName';
}
