import 'package:raheeq_main/models/review_model.dart';

class OrderResponseModel {
  final String id;
  final String subOrderNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final ParentOrder? parentOrder;
  final OrderProduct? product;
  final OrderFinancials? financials;
  final OrderTarget? target;
  final double totalAmount;
  final Map<String, dynamic>? locationDetails;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? deliveryProof;
  final Map<String, dynamic>? giftCard;
  final String? invoiceUrl;
  final Map<String, dynamic>? deliveredLocationDetails;
  final bool? isChillerAvailable;
  ReviewModel? review;

  OrderResponseModel({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.parentOrder,
    this.product,
    this.financials,
    this.target,
    required this.totalAmount,
    this.locationDetails,
    this.driver,
    this.deliveryProof,
    this.giftCard,
    this.invoiceUrl,
    this.deliveredLocationDetails,
    this.isChillerAvailable,
    this.review,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
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
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : (json['deliveryProof'] != null &&
                    json['deliveryProof']['deliveredAt'] != null
                ? DateTime.tryParse(json['deliveryProof']['deliveredAt'])
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
      financials: json['financials'] != null
          ? OrderFinancials.fromJson(json['financials'])
          : null,
      target: json['target'] != null
          ? OrderTarget.fromJson(json['target'])
          : null,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      locationDetails: json['locationDetails'],
      driver: json['driver'],
      deliveryProof: json['deliveryProof'],
      giftCard: json['giftCard'],
      invoiceUrl:
          json['invoice'] ??
          json['invoiceUrl'] ??
          json['invoice_url'] ??
          json['invoicePdfUrl'] ??
          json['invoicePdf'] ??
          (json['parentOrder'] != null
              ? (json['parentOrder']['invoicePdfUrl'] ??
                    json['parentOrder']['invoiceUrl'] ??
                    json['parentOrder']['invoice'] ??
                    json['parentOrder']['invoice_url'])
              : null),
      deliveredLocationDetails: json['deliveredLocationDetails'],
      isChillerAvailable: json['isChillerAvailable'],
      review: json['review'] != null ? ReviewModel.fromJson(json['review']) : null,
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
  final String image;
  final int quantity;

  OrderProduct({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.quantity,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'] ?? '',
      serialNumber: json['serialNumber'] ?? 0,
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}

class OrderFinancials {
  final double unitPrice;
  final double amount;
  final double deliveryFee;
  final double vatAmount;
  final double walletAmount;
  final double discountAmount;
  final double totalAmount;

  OrderFinancials({
    required this.unitPrice,
    required this.amount,
    required this.deliveryFee,
    required this.vatAmount,
    required this.walletAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  factory OrderFinancials.fromJson(Map<String, dynamic> json) {
    return OrderFinancials(
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      vatAmount: (json['vatAmount'] ?? 0).toDouble(),
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
