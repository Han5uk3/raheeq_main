import 'city.dart';
import 'place.dart';

class Mosque implements Place {
  final String id;
  final String name;
  final String nameAr;
  final String type;
  final double latitude;
  final double longitude;
  final String address;
  final String? image;
  final Zone? zone;

  Mosque({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.image,
    this.zone,
  });

  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      type: json['type'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      image: json['image'] as String?,
      zone: json['zone'] != null ? Zone.fromJson(json['zone'] as Map<String, dynamic>) : null,
    );
  }

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}

class Zone {
  final String name;
  final String nameAr;
  final City? city;

  Zone({
    required this.name,
    required this.nameAr,
    this.city,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      name: json['name'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      city: json['city'] != null ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
    );
  }

  String localizedName(bool isAr) {
    return isAr ? nameAr : name;
  }
}
