class BannerData {
  final String id;
  final String name;
  final String image;
  final int order;

  const BannerData({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
  });

  factory BannerData.fromJson(Map<String, dynamic> json) {
    return BannerData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'order': order,
    };
  }
}
