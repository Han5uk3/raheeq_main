class SubscriptionModel {
  final String id;
  final String subscriptionNumber;
  final String planName;
  final String planNameAr;
  final String planImage;
  final String frequency;
  final String status;
  final DateTime purchasedDate;
  final DateTime startDate;
  final DateTime endDate;
  final String targetName;
  final String targetNameAr;

  SubscriptionModel({
    required this.id,
    required this.subscriptionNumber,
    required this.planName,
    required this.planNameAr,
    required this.planImage,
    required this.frequency,
    required this.status,
    required this.purchasedDate,
    required this.startDate,
    required this.endDate,
    this.targetName = '',
    this.targetNameAr = '',
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      subscriptionNumber: json['subscriptionNumber'] ?? '',
      planName: json['planName'] ?? '',
      planNameAr: json['planNameAr'] ?? '',
      planImage: json['planImage'] ?? '',
      frequency: json['frequency'] ?? '',
      status: json['status'] ?? '',
      purchasedDate: json['purchasedDate'] != null
          ? DateTime.parse(json['purchasedDate'])
          : DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : DateTime.now(),
      targetName: json['target'] != null ? (json['target']['label'] ?? '') : (json['targetName'] ?? ''),
      targetNameAr: json['target'] != null ? (json['target']['labelAr'] ?? '') : (json['targetNameAr'] ?? ''),
    );
  }
}
