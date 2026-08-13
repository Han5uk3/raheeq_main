import 'package:raheeq_main/utils/formatters.dart';

class Product {
  final String id;
  final int serialNumber;
  final String name;
  final String nameAr;
  final String subtitle;
  final String subtitleAr;
  final String? subtitlePlural;
  final String? subtitlePluralAr;
  final String? message;
  final String? messageAr;
  final double price;
  final double deliveryFee;
  final String image;
  final String? bannerImage;
  final bool isHighNeed;
  final List<int> presetQuantities;
  final int minQuantity;

  const Product({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.nameAr,
    required this.subtitle,
    required this.subtitleAr,
    this.subtitlePlural,
    this.subtitlePluralAr,
    this.message,
    this.messageAr,
    required this.price,
    this.deliveryFee = 0.0,
    required this.image,
    this.bannerImage,
    required this.isHighNeed,
    required this.presetQuantities,
    required this.minQuantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPresets = json['presetQuantities'] as List<dynamic>?;
    return Product(
      id: json['id'] as String? ?? '',
      serialNumber: (json['serialNumber'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      subtitleAr: json['subtitleAr'] as String? ?? '',
      subtitlePlural: json['subtitlePlural'] as String?,
      subtitlePluralAr: json['subtitlePluralAr'] as String?,
      message: json['message'] as String?,
      messageAr: json['messageAr'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] as String? ?? '',
      bannerImage: json['bannerImage'] as String?,
      isHighNeed: json['isHighNeed'] == true,
      presetQuantities:
          rawPresets?.map((e) => (e as num).toInt()).toList() ?? [],
      minQuantity: (json['minQuantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serialNumber': serialNumber,
      'name': name,
      'nameAr': nameAr,
      'subtitle': subtitle,
      'subtitleAr': subtitleAr,
      'subtitlePlural': subtitlePlural,
      'subtitlePluralAr': subtitlePluralAr,
      'message': message,
      'messageAr': messageAr,
      'price': price,
      'deliveryFee': deliveryFee,
      'image': image,
      'bannerImage': bannerImage,
      'isHighNeed': isHighNeed,
      'presetQuantities': presetQuantities,
      'minQuantity': minQuantity,
    };
  }

  /// Returns the localised display name.
  String localizedName(bool isAr) => isAr ? nameAr : name;

  /// Returns the localised subtitle.
  String localizedSubtitle(bool isAr) => isAr ? subtitleAr : subtitle;

  /// Returns the localised plural subtitle, or null if unset/blank.
  String? localizedSubtitlePlural(bool isAr) {
    final value = isAr ? subtitlePluralAr : subtitlePlural;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Returns the localised message (may be null).
  String? localizedMessage(bool isAr) => isAr ? messageAr : message;

  /// Sorted list of valid selectable quantities.
  /// minQuantity is always the first entry; presets >= minQuantity follow.
  List<int> get validQuantities {
    final quantities = <int>{minQuantity};
    quantities.addAll(presetQuantities.where((q) => q >= minQuantity));
    return quantities.toList()..sort();
  }

  /// Formats the unit price as a localised string (including delivery fee).
  String formattedPrice(String suffix) {
    final double totalUnitPrice = price + deliveryFee;
    final formatted = Formatters.formatPrice(totalUnitPrice);
    return '\u202A$suffix $formatted\u202C';
  }
}
