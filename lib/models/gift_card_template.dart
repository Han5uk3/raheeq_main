class GiftCardTemplate {
  final String id;
  final String name;
  final String nameAr;
  final String image;
  final bool isActive;
  final int sortOrder;

  GiftCardTemplate({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.isActive,
    required this.sortOrder,
  });

  factory GiftCardTemplate.fromJson(Map<String, dynamic> json) {
    return GiftCardTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}
