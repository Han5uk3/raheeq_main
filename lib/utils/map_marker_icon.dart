import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerIcon {
  static Future<BitmapDescriptor?> load() async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/others/map_icon.png',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<BitmapDescriptor?> loadSelected() async {
    try {
      return await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/others/map_pin_green.png',
      );
    } catch (_) {
      return null;
    }
  }
}
