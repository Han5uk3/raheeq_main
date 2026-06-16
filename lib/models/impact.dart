class ImpactModel {
  final double totalAmountPaid;
  final int totalOrders;
  final int totalSubscriptions;
  final int totalMosques;
  final int totalOrphanages;
  final int totalProducts;
  final List<ImpactProductBreakup> productsBreakup;

  ImpactModel({
    required this.totalAmountPaid,
    required this.totalOrders,
    required this.totalSubscriptions,
    required this.totalMosques,
    required this.totalOrphanages,
    required this.totalProducts,
    required this.productsBreakup,
  });

  factory ImpactModel.fromJson(Map<String, dynamic> json) {
    return ImpactModel(
      totalAmountPaid: (json['totalAmountPaid'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSubscriptions: json['totalSubscriptions'] as int? ?? 0,
      totalMosques: json['totalMosques'] as int? ?? 0,
      totalOrphanages: json['totalOrphanages'] as int? ?? 0,
      totalProducts: json['totalProducts'] as int? ?? 0,
      productsBreakup: (json['productsBreakup'] as List<dynamic>?)
              ?.map((e) => ImpactProductBreakup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ImpactProductBreakup {
  final String productId;
  final String name;
  final String nameAr;
  final String image;
  final int totalQuantity;

  ImpactProductBreakup({
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.totalQuantity,
  });

  factory ImpactProductBreakup.fromJson(Map<String, dynamic> json) {
    return ImpactProductBreakup(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      image: json['image'] as String? ?? '',
      totalQuantity: json['totalQuantity'] as int? ?? 0,
    );
  }

  String localizedName(bool isAr) {
    return isAr ? (nameAr.isNotEmpty ? nameAr : name) : name;
  }
}
