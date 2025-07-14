abstract class MapProvider {
  void init();
  void moveTo(double lat, double lng, double zoom);
  void addMarker(double lat, double lng);
  void addPolyline(List<dynamic> points, {int color = 0xFF0000FF});
  void clear();
}
