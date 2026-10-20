import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pin icons for the map, in the size they are drawn at.
///
/// The pin artwork is 1024px square. Handed to the map as an asset, each pin
/// decoded all of it again and scaled it down, on Android's main thread,
/// which Dart shares, so swapping in a page of pins stalled the map. The
/// artwork is scaled once here instead, off that thread, and every pin shares
/// the small copy.
class MapMarkerIcon {
  // Logical pixels, as wide as tall.
  static const double _size = 48;

  static Future<BitmapDescriptor?> load() =>
      _load('assets/others/map_icon.png');

  static Future<BitmapDescriptor?> loadSelected() =>
      _load('assets/others/map_pin_green.png');

  static Future<BitmapDescriptor?> _load(String assetName) async {
    try {
      final devicePixelRatio =
          ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
      final data = await rootBundle.load(assetName);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: (_size * devicePixelRatio).round(),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (png == null) return null;
      return BitmapDescriptor.bytes(
        png.buffer.asUint8List(),
        imagePixelRatio: devicePixelRatio,
        width: _size,
        height: _size,
      );
    } catch (_) {
      return null;
    }
  }
}
