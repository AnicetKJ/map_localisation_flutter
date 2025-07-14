import '../models/route.dart';
import '../models/tracked_object.dart';

class SimulationService {
  RouteModel route;
  TrackedObject object;
  int currentIndex = 0;

  SimulationService({required this.route, required this.object});

  void reset() {
    currentIndex = 0;
    object.position = route.points.first;
  }

  bool nextStep() {
    if (currentIndex < route.points.length - 1) {
      currentIndex++;
      object.position = route.points[currentIndex];
      return true;
    }
    return false;
  }
}
