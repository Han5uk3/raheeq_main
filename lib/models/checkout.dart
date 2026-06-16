import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/category.dart';

class Checkout {
  final String id;
  final String userId;
  final String? campaignId;
  final dynamic campaign;
  final bool useWallet;
  final String? couponCode;
  final dynamic couponDetails;
  final double walletBalance;
  final dynamic subscription;
  final int occurrences;
  final bool isFreeDelivery;
  final List<CheckoutItem> items;
  final double subTotal;
  final double totalDeliveryFee;
  final double totalGiftCardFee;
  final double discountAmount;
  final double vatAmount;
  final double totalBeforeWallet;
  final double walletAmountUsed;
  final double finalTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Checkout({
    required this.id,
    required this.userId,
    this.campaignId,
    this.campaign,
    required this.useWallet,
    this.couponCode,
    this.couponDetails,
    required this.walletBalance,
    this.subscription,
    required this.occurrences,
    required this.isFreeDelivery,
    required this.items,
    required this.subTotal,
    required this.totalDeliveryFee,
    required this.totalGiftCardFee,
    required this.discountAmount,
    required this.vatAmount,
    required this.totalBeforeWallet,
    required this.walletAmountUsed,
    required this.finalTotal,
    this.createdAt,
    this.updatedAt,
  });

  factory Checkout.fromJson(Map<String, dynamic> json) {
    return Checkout(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      campaignId: json['campaignId'],
      campaign: json['campaign'],
      useWallet: json['wallet']?['isUsed'] ?? json['useWallet'] ?? false,
      couponCode: json['couponCode'],
      couponDetails: json['couponDetails'],
      walletBalance:
          (json['wallet']?['balance'] as num?)?.toDouble() ??
          (json['walletBalance'] as num?)?.toDouble() ??
          0.0,
      subscription: json['subscription'],
      occurrences: (json['occurrences'] as num?)?.toInt() ?? 1,
      isFreeDelivery:
          json['pricing']?['isFreeDelivery'] ?? json['isFreeDelivery'] ?? false,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => CheckoutItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      subTotal:
          (json['pricing']?['subTotal'] as num?)?.toDouble() ??
          (json['subTotal'] as num?)?.toDouble() ??
          0.0,
      totalDeliveryFee:
          (json['pricing']?['deliveryFee'] as num?)?.toDouble() ??
          (json['totalDeliveryFee'] as num?)?.toDouble() ??
          0.0,
      totalGiftCardFee:
          (json['pricing']?['giftCardFee'] as num?)?.toDouble() ??
          (json['totalGiftCardFee'] as num?)?.toDouble() ??
          0.0,
      discountAmount:
          (json['pricing']?['discountAmount'] as num?)?.toDouble() ??
          (json['discountAmount'] as num?)?.toDouble() ??
          0.0,
      vatAmount:
          (json['pricing']?['vatAmount'] as num?)?.toDouble() ??
          (json['vatAmount'] as num?)?.toDouble() ??
          0.0,
      totalBeforeWallet:
          (json['pricing']?['totalBeforeWallet'] as num?)?.toDouble() ??
          (json['totalBeforeWallet'] as num?)?.toDouble() ??
          0.0,
      walletAmountUsed:
          (json['wallet']?['amountUsed'] as num?)?.toDouble() ??
          (json['walletAmountUsed'] as num?)?.toDouble() ??
          0.0,
      finalTotal:
          (json['pricing']?['finalTotal'] as num?)?.toDouble() ??
          (json['finalTotal'] as num?)?.toDouble() ??
          0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class CheckoutItem {
  final dynamic city;
  final String? note;
  final String? cityId;
  final Product? product;
  final Category? category;
  final dynamic giftCard;
  final dynamic location;
  final int quantity;
  final String productId;
  final double unitPrice;
  final String? locationId;
  final double totalPrice;
  final double deliveryFee;
  final double giftCardFee;
  final String? categorySlug;

  CheckoutItem({
    this.city,
    this.note,
    this.cityId,
    this.product,
    this.category,
    this.giftCard,
    this.location,
    required this.quantity,
    required this.productId,
    required this.unitPrice,
    this.locationId,
    required this.totalPrice,
    required this.deliveryFee,
    required this.giftCardFee,
    this.categorySlug,
  });

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      city: json['city'],
      note: json['note'],
      cityId: json['cityId'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      giftCard: json['giftCard'],
      location: json['location'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      productId: json['productId'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      locationId: json['locationId'],
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      giftCardFee: (json['giftCardFee'] as num?)?.toDouble() ?? 0.0,
      categorySlug: json['categorySlug'],
    );
  }
}
