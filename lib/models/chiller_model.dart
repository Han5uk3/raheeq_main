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

  /// Whether this is a live chiller the user owns: delivered, and not
  /// decommissioned or temporarily withdrawn. This is what "My Chillers"
  /// lists — a unit still on its way is not one of them yet.
  bool get isActive => status == 'CONFIRMED' && isChillerAvailable;

  /// Whether a refill can be ordered for this chiller: it is live, and it has a
  /// venue to deliver the refill to. Mirrors what the checkout validates, so
  /// the refill button is only offered where the order would actually go
  /// through — a chiller with no location has no destination id to send, and
  /// the checkout rejects an item without one.
  ///
  /// A chiller can be listed without being refillable, so this gates the refill
  /// button only; use [isActive] to decide what appears in the list.
  bool get canRefill => isActive && deliveredLocation != null;

  /// The destination fields a refill checkout item carries for this chiller.
  ///
  /// A chiller is seeded at a mosque or an orphanage, so normally this is the
  /// delivered location's own id as `locationId`. A chiller placed against a
  /// city rather than a single venue carries `cityId` instead, and one with no
  /// location at all falls back to the category the chiller sits under — the
  /// backend rejects that case (`chillerHasNoLocation`), so sending an empty
  /// id here would only turn a clear error into a confusing one.
  Map<String, dynamic> get checkoutDestination {
    final location = deliveredLocation;
    if (location == null) return const {};
    if (location.id.isNotEmpty) return {'locationId': location.id};
    if (location.cityId != null && location.cityId!.isNotEmpty) {
      return {'cityId': location.cityId!};
    }
    if (location.categoryId != null && location.categoryId!.isNotEmpty) {
      return {'categoryId': location.categoryId!};
    }
    return const {};
  }

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
      // A chiller that has not been assigned a venue yet comes back with a
      // null location, so every reader has to cope with its absence.
      deliveredLocation: json['deliveredLocation'] != null
          ? ChillerDeliveredLocation.fromJson(json['deliveredLocation'])
          : null,
    );
  }
}

class ChillerProduct {
  final String id;
  final String name;
  final String nameAr;
  final String image;

  /// `2` marks the product as a chiller unit; refill cartons are 1 and 4. The
  /// my-chillers endpoint only returns chillers, so this is absent there.
  final int? serialNumber;

  ChillerProduct({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
    this.serialNumber,
  });

  factory ChillerProduct.fromJson(Map<String, dynamic> json) {
    return ChillerProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      image: json['image'] as String? ?? '',
      serialNumber: (json['serialNumber'] as num?)?.toInt(),
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

  /// Where the chiller sits: `MOSQUE`, `ORPHANAGE`, `MEQAT_MOSQUE`, …
  final String type;

  /// Only present when the chiller is tied to a city or a category rather than
  /// to a single venue.
  final String? cityId;
  final String? categoryId;

  ChillerDeliveredLocation({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.cityId,
    this.categoryId,
  });

  /// The order category this location belongs to, so a refill is filed under
  /// the same category the chiller was ordered under.
  ///
  /// The API names the type in upper snake case (`MOSQUE`) while categories are
  /// slugged (`specific_mosque`), so the two never match on their own.
  String get categorySlug {
    switch (type.toUpperCase()) {
      case 'ORPHANAGE':
        return 'orphanages';
      case 'MEQAT_MOSQUE':
        return 'meqat_mosques';
      case 'MOSQUE':
      default:
        return 'specific_mosque';
    }
  }

  factory ChillerDeliveredLocation.fromJson(Map<String, dynamic> json) {
    return ChillerDeliveredLocation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
      cityId: json['cityId'] as String?,
      categoryId: json['categoryId'] as String?,
    );
  }
}
