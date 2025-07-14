import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

Future<LatLng?> searchPlace(String query) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
  );
  final response = await http.get(url, headers: {
    'User-Agent': 'flutter_map_app/1.0'
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data.isNotEmpty) {
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      return LatLng(lat, lon);
    }
  }
  return null;
}

Future<List<Map<String, dynamic>>> searchPlaces(String query, {int limit = 10}) async {
  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=$limit',
  );
  final response = await http.get(url, headers: {
    'User-Agent': 'flutter_map_app/1.0'
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }
  return [];
}