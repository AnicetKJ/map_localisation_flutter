import '../models/tracked_object.dart';
import 'package:latlong2/latlong.dart';

class TrackingService {
  final List<TrackedObject> trackedObjects = [];

  void addObject(TrackedObject obj) {
    trackedObjects.add(obj);
  }

  void updatePosition(String id, double lat, double lng) {
    final obj = trackedObjects.firstWhere((o) => o.id == id, orElse: () => throw Exception('Not found'));
    obj.position = LatLng(lat, lng);
  }

  void removeObject(String id) {
    trackedObjects.removeWhere((o) => o.id == id);
  }
}
