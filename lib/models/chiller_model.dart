class ChillerModel {
  final String id;
  final String subOrderNumber;
  final String status;
  final DateTime? deliveredAt;
  final bool isChillerAvailable;

  /// How many times this chiller has been refilled, counting only refills that
  /// have been delivered.
  final int refillCount;

  /// When the most recent refill was delivered, or null if it never has been.
  final DateTime? lastRefilledDate;
  final ChillerProduct? product;
  final ChillerDeliveredLocation? deliveredLocation;

  ChillerModel({
    required this.id,
    required this.subOrderNumber,
    required this.status,
    this.deliveredAt,
    required this.isChillerAvailable,
    this.refillCount = 0,
    this.lastRefilledDate,
    this.product,
    this.deliveredLocation,
  });

  /// Whether this chiller can be refilled: it has been delivered and is still
  /// accepting refills. Mirrors what the checkout validates, so the refill
  /// button is only offered where the order would actually go through.
  bool get canRefill => status == 'CONFIRMED' && isChillerAvailable;

  factory ChillerModel.fromJson(Map<String, dynamic> json) {
    return ChillerModel(
      id: json['id'] as String,
      subOrderNumber: json['subOrderNumber'] as String,
      status: json['status'] as String,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      isChillerAvailable: json['isChillerAvailable'] as bool? ?? false,
      refillCount: (json['refillCount'] as num?)?.toInt() ?? 0,
      lastRefilledDate: json['lastRefilledDate'] != null
          ? DateTime.tryParse(json['lastRefilledDate'])
          : null,
      product: json['product'] != null
          ? ChillerProduct.fromJson(json['product'])
          : null,
      deliveredLocation: json['deliveredLocation'] != null
          ? ChillerDeliveredLocation.fromJson(json['deliveredLocation'])
          : null,
    );
  }
}

class ChillerProduct {
  final String name;
  final String nameAr;
  final String image;

  ChillerProduct({
    required this.name,
    required this.nameAr,
    required this.image,
  });

  factory ChillerProduct.fromJson(Map<String, dynamic> json) {
    return ChillerProduct(
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );
  }
}

class ChillerDeliveredLocation {
  final String id;
  final String name;
  final String nameAr;
  final String address;
  final double latitude;
  final double longitude;
  final String type;

  ChillerDeliveredLocation({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  factory ChillerDeliveredLocation.fromJson(Map<String, dynamic> json) {
    return ChillerDeliveredLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
    );
  }
}
