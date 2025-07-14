import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_provider.dart';

class FlutterMapProvider implements MapProvider {
  final MapController controller;
  FlutterMapProvider(this.controller);

  @override
  void init() {}

  @override
  void moveTo(double lat, double lng, double zoom) {
    controller.move(LatLng(lat, lng), zoom);
  }

  @override
  void addMarker(double lat, double lng) {
    // À implémenter selon l'architecture UI
  }

  @override
  void addPolyline(List points, {int color = 0xFF0000FF}) {
    // À implémenter selon l'architecture UI
  }

  @override
  void clear() {
    // À implémenter selon l'architecture UI
  }
}
