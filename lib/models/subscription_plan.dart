enum SubscriptionFrequency { everyDay, onceAWeek, twiceAWeek, monthly, unknown }

class SubscriptionPlan {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final num price;
  final SubscriptionFrequency frequency;
  final List<int>? allowedDays;
  final String? image;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.price,
    required this.frequency,
    this.allowedDays,
    this.image,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    SubscriptionFrequency parseFrequency(String? type) {
      if (type == null) return SubscriptionFrequency.unknown;
      switch (type.toUpperCase()) {
        case 'EVERYDAY':
        case 'EVERY_DAY':
        case 'DAILY':
          return SubscriptionFrequency.everyDay;
        case 'ONCE_A_WEEK':
        case 'WEEKLY':
          return SubscriptionFrequency.onceAWeek;
        case 'TWICE_A_WEEK':
          return SubscriptionFrequency.twiceAWeek;
        case 'MONTHLY':
        case 'ONCE_A_MONTH':
          return SubscriptionFrequency.monthly;
        default:
          return SubscriptionFrequency.unknown;
      }
    }

    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      nameAr: json['nameAr'] ?? json['titleAr'] ?? '',
      description: json['description'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      price: json['price'] ?? 0,
      frequency: parseFrequency(json['type'] ?? json['frequency']),
      allowedDays: (json['allowedDays'] as List<dynamic>?)?.cast<int>(),
      image: json['image'],
    );
  }

  String localizedName(bool isAr) => isAr && nameAr.isNotEmpty ? nameAr : name;
  String localizedDescription(bool isAr) =>
      isAr && descriptionAr.isNotEmpty ? descriptionAr : description;
}
