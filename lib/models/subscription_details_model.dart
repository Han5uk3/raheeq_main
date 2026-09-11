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
  final List<DeliveryLocation> deliveryLocations;
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
    this.deliveryLocations = const [],
    this.products = const [],
  });

  factory SubscriptionDetailsModel.fromJson(Map<String, dynamic> json) {
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
      targetName: json['target'] != null ? (json['target']['label'] ?? '') : (json['targetName'] ?? ''),
      targetNameAr: json['target'] != null ? (json['target']['labelAr'] ?? '') : (json['targetNameAr'] ?? ''),
      monthsCount: json['monthsCount'],
      ordersCount: json['ordersCount'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      invoiceUrl: json['invoiceUrl'],
      deliveries:
          (json['deliveries'] as List<dynamic>?)
              ?.map((e) => SubscriptionDeliveryModel.fromJson(e))
              .toList() ??
          [],
      giftCards: json['giftCards'] ?? (json['giftCard'] != null ? [json['giftCard']] : []),
      completeCount: json['completedCount'] ?? 0,
      deliveryLocations:
          (json['deliveryLocations'] as List<dynamic>?)
              ?.map((e) => DeliveryLocation.fromJson(e))
              .toList() ??
          [],
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
  final List<SubscriptionSubOrderModel> subOrders;

  SubscriptionDeliveryModel({
    required this.orderId,
    required this.orderNumber,
    this.scheduledDate,
    required this.createdAt,
    required this.status,
    required this.subOrders,
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
      subOrders:
          (json['subOrders'] as List<dynamic>?)
              ?.map((e) => SubscriptionSubOrderModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubscriptionSubOrderModel {
  final String id;
  final String subOrderNumber;
  final String status;
  final double totalAmount;
  final SubscriptionProductModel? product;
  final SubscriptionTargetModel? target;
  final String? deliveryProof;
  final Map<String, dynamic>? giftCard;
  final bool? deliveredToDifferentMosque;
  final String? differentMosqueReason;

  SubscriptionSubOrderModel({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    required this.totalAmount,
    this.product,
    this.target,
    this.deliveryProof,
    this.giftCard,
    this.deliveredToDifferentMosque,
    this.differentMosqueReason,
  });

  factory SubscriptionSubOrderModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionSubOrderModel(
      id: json['id'] ?? '',
      subOrderNumber: json['subOrderNumber'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      product: json['product'] != null
          ? SubscriptionProductModel.fromJson(json['product'])
          : null,
      target: json['target'] != null
          ? SubscriptionTargetModel.fromJson(json['target'])
          : null,
      deliveryProof: json['deliveryProof'],
      giftCard: json['giftCard'],
      deliveredToDifferentMosque: json['deliveredToDifferentMosque'],
      differentMosqueReason: json['differentMosqueReason'],
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
class DeliveryLocation {
  final String id;
  final String name;
  final String nameAr;
  final String address;

  DeliveryLocation({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.address,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String nameAr;
  final String image;

  ProductModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
