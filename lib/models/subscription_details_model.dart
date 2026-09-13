import 'package:raheeq_main/models/subscription_model.dart';

class SubscriptionDetailsModel extends SubscriptionModel {
  final int? monthsCount;
  final int ordersCount;
  final String paymentMethod;
  final double totalAmount;
  final String? invoiceUrl;
  final List<SubscriptionDeliveryModel> deliveries;
  final List<dynamic> giftCards;
  final int completeCount;

  /// Days left on the subscription, counted on the server in Riyadh time.
  final int? daysLeft;

  /// How far through its duration the subscription is, from 0 to 100.
  final double progressPercentage;
  final List<SubscriptionTarget> targets;
  final List<ProductModel> products;

  SubscriptionDetailsModel({
    required super.id,
    required super.subscriptionNumber,
    required super.planName,
    required super.planNameAr,
    required super.planImage,
    required super.frequency,
    required super.status,
    required super.purchasedDate,
    required super.startDate,
    required super.endDate,
    super.targetName,
    super.targetNameAr,
    this.monthsCount,
    required this.ordersCount,
    required this.paymentMethod,
    required this.totalAmount,
    this.invoiceUrl,
    required this.deliveries,
    this.giftCards = const [],
    this.completeCount = 0,
    this.daysLeft,
    this.progressPercentage = 0,
    this.targets = const [],
    this.products = const [],
  });

  factory SubscriptionDetailsModel.fromJson(Map<String, dynamic> json) {
    final targets =
        ((json['targets'] ?? json['deliveryLocations']) as List<dynamic>?)
            ?.map((e) => SubscriptionTarget.fromJson(e))
            .toList() ??
        <SubscriptionTarget>[];

    return SubscriptionDetailsModel(
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
      targetName: json['target'] != null
          ? (json['target']['label'] ?? '')
          : (json['targetName'] ??
                (targets.isNotEmpty ? targets.first.name : '')),
      targetNameAr: json['target'] != null
          ? (json['target']['labelAr'] ?? '')
          : (json['targetNameAr'] ??
                (targets.isNotEmpty ? targets.first.nameAr : '')),
      monthsCount: json['monthsCount'],
      ordersCount: json['totalOrdersCount'] ?? json['ordersCount'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      invoiceUrl: json['invoiceUrl'],
      deliveries:
          (json['deliveries'] as List<dynamic>?)
              ?.map((e) => SubscriptionDeliveryModel.fromJson(e))
              .toList() ??
          [],
      giftCards: json['giftCards'] ?? (json['giftCard'] != null ? [json['giftCard']] : []),
      completeCount:
          json['completedOrdersCount'] ?? json['completedCount'] ?? 0,
      daysLeft: (json['daysLeft'] as num?)?.toInt(),
      progressPercentage: (json['progressPercentage'] ?? 0).toDouble(),
      targets: targets,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => ProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubscriptionDeliveryModel {
  final String orderId;
  final String orderNumber;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final String status;

  /// The delivery day as `YYYY-MM-DD`, already in Riyadh time.
  final String? date;
 

  SubscriptionDeliveryModel({
    required this.orderId,
    required this.orderNumber,
    this.scheduledDate,
    required this.createdAt,
    required this.status,
    this.date,
  });

  factory SubscriptionDeliveryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionDeliveryModel(
      orderId: json['orderId'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      date: json['date'],
      
    );
  }
}



class SubscriptionProductModel {
  final String id;
  final int serialNumber;
  final String name;
  final String nameAr;
  final String image;
  final int quantity;

  SubscriptionProductModel({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.quantity,
  });

  factory SubscriptionProductModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionProductModel(
      id: json['id'] ?? '',
      serialNumber: json['serialNumber'] ?? 0,
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}

class SubscriptionTargetModel {
  final String type;
  final String label;
  final String labelAr;
  final String image;

  SubscriptionTargetModel({
    required this.type,
    required this.label,
    required this.labelAr,
    required this.image,
  });

  factory SubscriptionTargetModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionTargetModel(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      labelAr: json['labelAr'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
class SubscriptionTarget {
  final String id;
  final String type;
  final String name;
  final String nameAr;
  final String address;
  final String image;

  SubscriptionTarget({
    required this.id,
    this.type = '',
    required this.name,
    required this.nameAr,
    this.address = '',
    this.image = '',
  });

  factory SubscriptionTarget.fromJson(Map<String, dynamic> json) {
    return SubscriptionTarget(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      address: json['address'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String nameAr;
  final String image;
  final int quantity;

  ProductModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
    this.quantity = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}
