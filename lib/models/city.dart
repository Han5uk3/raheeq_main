class City {
  final String id;
  final String name;
  final String nameAr;
  // Present on cities from /geography/cities; a city nested in a place's
  // JSON may come without them.
  final double? latitude;
  final double? longitude;

  City({
    required this.id,
    required this.name,
    required this.nameAr,
    this.latitude,
    this.longitude,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}
