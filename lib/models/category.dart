class Category {
  final String id;
  final String slug;
  final String labelEn;
  final String labelAr;
  final String image;
  final String? mostInNeedLabelEn;
  final String? mostInNeedLabelAr;
  final String? specificLabelEn;
  final String? specificLabelAr;
  final int sortOrder;

  const Category({
    required this.id,
    required this.slug,
    required this.labelEn,
    required this.labelAr,
    required this.image,
    this.mostInNeedLabelEn,
    this.mostInNeedLabelAr,
    this.specificLabelEn,
    this.specificLabelAr,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      labelAr: json['labelAr'] as String? ?? '',
      image: json['image'] as String? ?? '',
      mostInNeedLabelEn: json['mostInNeedLabelEn'] as String?,
      mostInNeedLabelAr: json['mostInNeedLabelAr'] as String?,
      specificLabelEn: json['specificLabelEn'] as String?,
      specificLabelAr: json['specificLabelAr'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'labelEn': labelEn,
      'labelAr': labelAr,
      'image': image,
      'mostInNeedLabelEn': mostInNeedLabelEn,
      'mostInNeedLabelAr': mostInNeedLabelAr,
      'specificLabelEn': specificLabelEn,
      'specificLabelAr': specificLabelAr,
      'sortOrder': sortOrder,
    };
  }

  /// Returns the localised display label.
  String localizedLabel(bool isAr) => isAr ? labelAr : labelEn;

  /// Returns the best available subtitle: specificLabel → mostInNeedLabel → null.
  String? localizedSubtitle(bool isAr) {
    final specific = isAr ? specificLabelAr : specificLabelEn;
    if (specific != null && specific.isNotEmpty) return specific;
    final mostInNeed = isAr ? mostInNeedLabelAr : mostInNeedLabelEn;
    if (mostInNeed != null && mostInNeed.isNotEmpty) return mostInNeed;
    return null;
  }
}
