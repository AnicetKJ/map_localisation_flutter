import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
  final url = Uri.parse(
    'http://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final coords = data['routes'][0]['geometry']['coordinates'] as List;
    return coords.map((c) => LatLng(c[1], c[0])).toList(); // [lon, lat] → LatLng(lat, lon)
  }
  return [];
}
