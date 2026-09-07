import 'package:raheeq_main/models/vat_rate.dart';

class OrderResponseModel {
  final String id;
  final String subOrderNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? assignedAt;

  /// When the order was accepted for delivery, and when it was handed over.
  /// Both are only sent by the orders-list endpoint, so they are null on the
  /// details payload and on orders that predate the fields.
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final ParentOrder? parentOrder;
  final OrderProduct? product;
  final OrderFinancials? financials;
  final OrderTarget? target;
  final double totalAmount;
  // The list endpoint returns these at the item root instead of inside
  // `financials`, so they are mirrored here and read from either place.
  final double walletAmount;
  final double discountAmount;
  final Map<String, dynamic>? locationDetails;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? deliveryProof;
  final Map<String, dynamic>? giftCard;
  final String? invoiceUrl;
  final Map<String, dynamic>? deliveredLocationDetails;
  final bool? isChillerAvailable;

  /// Whether this order is a refill delivered to a chiller the customer
  /// already owns, rather than a standalone water order. Absent on older
  /// payloads, which is read as "not a refill".
  final bool isChillerRefill;
  OrderReviewModel? review;
  final bool? deliveredToDifferentMosque;
  final String? differentMosqueReason;

  OrderResponseModel({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.acceptedAt,
    this.deliveredAt,
    this.completedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.parentOrder,
    this.product,
    this.financials,
    this.target,
    required this.totalAmount,
    this.walletAmount = 0,
    this.discountAmount = 0,
    this.locationDetails,
    this.driver,
    this.deliveryProof,
    this.giftCard,
    this.invoiceUrl,
    this.deliveredLocationDetails,
    this.isChillerAvailable,
    this.isChillerRefill = false,
    this.review,
    this.deliveredToDifferentMosque,
    this.differentMosqueReason,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    final financialsJson = json['financials'] is Map<String, dynamic>
        ? json['financials'] as Map<String, dynamic>
        : null;

    return OrderResponseModel(
      id: json['id'] ?? '',
      subOrderNumber: json['subOrderNumber'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])
          : (json['dispatchedAt'] != null
                ? DateTime.tryParse(json['dispatchedAt'])
                : null),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : ((json['deliveryProof'] ?? json['proofs']) != null &&
                    (json['deliveryProof'] ?? json['proofs'])['deliveredAt'] !=
                        null
                ? DateTime.tryParse(
                    (json['deliveryProof'] ?? json['proofs'])['deliveredAt'],
                  )
                : null),
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.tryParse(json['confirmedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      parentOrder: json['parentOrder'] != null
          ? ParentOrder.fromJson(json['parentOrder'])
          : null,
      product: json['product'] != null
          ? OrderProduct.fromJson(json['product'])
          : null,
      financials: financialsJson != null
          ? OrderFinancials.fromJson({
              // Like `walletAmount` below, the free-delivery fields turn up at
              // the item root on some endpoints, so fall back to them.
              for (final key in const [
                'isDeliveryFree',
                'isFreeDelivery',
                'freeDelivery',
                'originalDeliveryFee',
                'vatPercentage',
              ])
                if (financialsJson[key] == null && json[key] != null)
                  key: json[key],
              ...financialsJson,
            })
          : null,
      target: json['target'] != null
          ? OrderTarget.fromJson(json['target'])
          : null,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      walletAmount:
          (json['walletAmount'] ?? financialsJson?['walletAmount'] ?? 0)
              .toDouble(),
      discountAmount:
          (json['discountAmount'] ?? financialsJson?['discountAmount'] ?? 0)
              .toDouble(),
      locationDetails: json['locationDetails'],
      driver: json['driver'],
      deliveryProof: json['deliveryProof'] ?? json['proofs'],
      giftCard: json['giftCard'],
      invoiceUrl:
          json['invoice'] ??
          json['invoiceUrl'] ??
          json['invoice_url'] ??
          json['invoicePdfUrl'] ??
          json['invoicePdf'] ??
          json['invoice_link'] ??
          json['invoiceLink'] ??
          (json['parentOrder'] != null
              ? (json['parentOrder']['invoicePdfUrl'] ??
                    json['parentOrder']['invoiceUrl'] ??
                    json['parentOrder']['invoice'] ??
                    json['parentOrder']['invoice_url'] ??
                    json['parentOrder']['invoice_link'] ??
                    json['parentOrder']['invoiceLink'])
              : null),
      deliveredLocationDetails: json['deliveredLocationDetails'],
      isChillerAvailable: json['isChillerAvailable'],
      // Compared rather than cast: the field is missing on orders placed
      // before refills existed, and null there means false, not an error.
      isChillerRefill: json['isChillerRefill'] == true,
      review: json['review'] != null
          ? OrderReviewModel.fromJson(json['review'])
          : null,
      deliveredToDifferentMosque: json['deliveredToDifferentMosque'],
      differentMosqueReason: json['differentMosqueReason'],
    );
  }
}

class ParentOrder {
  final String orderNumber;
  final String paymentMethod;
  final String paymentStatus;
  final String? invoicePdfUrl;

  ParentOrder({
    required this.orderNumber,
    required this.paymentMethod,
    required this.paymentStatus,
    this.invoicePdfUrl,
  });

  factory ParentOrder.fromJson(Map<String, dynamic> json) {
    return ParentOrder(
      orderNumber: json['orderNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      invoicePdfUrl:
          json['invoicePdfUrl'] ??
          json['invoiceUrl'] ??
          json['invoice'] ??
          json['invoice_url'],
    );
  }
}

class OrderProduct {
  final String id;
  final int serialNumber;
  final String name;
  final String nameAr;
  final String? subtitle;
  final String? subtitleAr;
  final String? message;
  final String messageAr;
  final String image;
  final int quantity;

  OrderProduct({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.quantity,
    this.subtitle,
    this.subtitleAr,
    this.message,
    required this.messageAr,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'] ?? '',
      serialNumber: json['serialNumber'] ?? 0,
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
      subtitle: json['subtitle'] ?? '',
      subtitleAr: json['subtitleAr'] ?? '',
      message: json['message'] ?? '',
      messageAr: json['messageAr'] ?? '',
    );
  }
}

class OrderFinancials {
  final double unitPrice;
  final double amount;

  /// What delivery actually cost the customer — 0 on a free delivery.
  final double deliveryFee;

  /// What delivery would have cost, when the backend sends it separately.
  /// Null when the backend only reports one delivery figure.
  final double? originalDeliveryFee;

  /// The backend's explicit free-delivery flag, when it sends one.
  final bool isFreeDelivery;
  final double vatAmount;

  /// The VAT rate the backend applied to this order, as a percentage. Null on
  /// orders placed before the snapshot existed, which [vatRate] falls back for.
  final double? vatPercentage;
  final double walletAmount;
  final double discountAmount;
  final double totalAmount;

  OrderFinancials({
    required this.unitPrice,
    required this.amount,
    required this.deliveryFee,
    this.originalDeliveryFee,
    this.isFreeDelivery = false,
    required this.vatAmount,
    this.vatPercentage,
    required this.walletAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  /// The rate to label the VAT row with. Orders placed before the backend
  /// started snapshotting the rate carry none, so they fall back to the
  /// standard Saudi 15%.
  double get vatRate =>
      (vatPercentage ?? 0) > 0 ? vatPercentage! : defaultVatPercentage;

  /// Whether delivery ended up free. Either the backend says so outright, or
  /// it charged nothing while still reporting a non-zero original fee.
  bool get hasFreeDelivery =>
      isFreeDelivery || ((originalDeliveryFee ?? 0) > 0 && deliveryFee <= 0);

  /// The fee to strike through on a free delivery — the original where the
  /// backend sends one, otherwise the single figure it reported. Null when
  /// there is no fee worth striking through, so the UI shows only "Free".
  double? get strikethroughDeliveryFee {
    final original = originalDeliveryFee ?? deliveryFee;
    return original > 0 ? original : null;
  }

  factory OrderFinancials.fromJson(Map<String, dynamic> json) {
    return OrderFinancials(
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      originalDeliveryFee:
          (json['originalDeliveryFee'] ??
                  json['deliveryFeeBeforeDiscount'] ??
                  json['baseDeliveryFee'])
              ?.toDouble(),
      // The orders API names the flag `isDeliveryFree`; checkout and the older
      // order payloads name it the other way round.
      isFreeDelivery:
          json['isDeliveryFree'] ??
          json['isFreeDelivery'] ??
          json['freeDelivery'] ??
          false,
      vatAmount: (json['vatAmount'] ?? 0).toDouble(),
      vatPercentage: (json['vatPercentage'])?.toDouble(),
      walletAmount: (json['walletAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class OrderTarget {
  final String type;
  final String label;
  final String labelAr;
  final String image;

  OrderTarget({
    required this.type,
    required this.label,
    required this.labelAr,
    required this.image,
  });

  factory OrderTarget.fromJson(Map<String, dynamic> json) {
    return OrderTarget(
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      labelAr: json['labelAr'] ?? '',
      image: json['image'] ?? '',
    );
  }
}

class OrderReviewModel {
  final int rating;
  final String reviewText;

  OrderReviewModel({required this.rating, required this.reviewText});

  factory OrderReviewModel.fromJson(Map<String, dynamic> json) {
    return OrderReviewModel(
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'] ?? '',
    );
  }
}
