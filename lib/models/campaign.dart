import 'product.dart';

class Campaign {
  final String id;
  final String title;
  final String titleAr;
  final String description;
  final String descriptionAr;
  final String image;
  final bool canSubscribe;
  final int order;
  final List<Product> products;

  const Campaign({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.description,
    required this.descriptionAr,
    required this.image,
    required this.canSubscribe,
    required this.order,
    required this.products,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>?;
    return Campaign(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      image: json['image'] as String? ?? '',
      canSubscribe: json['canSubscribe'] == true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      products:
          rawProducts
              ?.map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'titleAr': titleAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'image': image,
      'canSubscribe': canSubscribe,
      'order': order,
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  /// Returns the localised title.
  String localizedTitle(bool isAr) => isAr ? titleAr : title;

  /// Returns the localised description.
  String localizedDescription(bool isAr) => isAr ? descriptionAr : description;
}
