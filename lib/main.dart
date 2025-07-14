import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'search_place.dart';
import 'get_route.dart';

void main() {
  runApp(const MaterialApp(
    home: MapSimulatePage(),
    debugShowCheckedModeBanner: false,));
}

class MapSimulatePage extends StatefulWidget {
  const MapSimulatePage({super.key});

  @override
  State<MapSimulatePage> createState() => _MapSimulatePageState();
}

class _MapSimulatePageState extends State<MapSimulatePage> {
  final mapController = MapController();
  List<LatLng> route = [];
  LatLng? currentPosition;
  Timer? _timer;
  bool isSimulating = false;
  double simulationSpeed = 500; // Vitesse par défaut

  // Pour la recherche et l'itinéraire
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  // Nouveaux états pour la logique UI
  bool showChoiceButtons = false;
  bool showSearchBar = false;
  bool showRouteBars = false;

  // Pour suggestions de chaque barre
  List<Map<String, dynamic>> searchSuggestions = [];
  List<Map<String, dynamic>> fromSuggestions = [];
  List<Map<String, dynamic>> toSuggestions = [];

  @override
  void dispose() {
    _timer?.cancel();
    searchController.dispose();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  Future<void> _getRoute() async {
    final from = await searchPlace(fromController.text);
    final to = await searchPlace(toController.text);
    if (from != null && to != null) {
      final newRoute = await getRoute(from, to);
      setState(() {
        route = newRoute;
        currentPosition = newRoute.isNotEmpty ? newRoute.first : null;
      });
      if (newRoute.isNotEmpty) {
        mapController.move(newRoute.first, 15);
      }
    }
  }

  void _simulateMovement() {
    if (route.isEmpty) return;
    _timer?.cancel();
    int index = 0;
    setState(() {
      isSimulating = true;
      currentPosition = route.first;
    });
    _timer = Timer.periodic(Duration(milliseconds: simulationSpeed.round()), (timer) {
      if (index >= route.length) {
        timer.cancel();
        setState(() => isSimulating = false);
        return;
      }
      setState(() {
        currentPosition = route[index];
      });
      index++;
    });
  }

  // Suggestions pour chaque barre
  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        searchSuggestions = [];
      });
      return;
    }
    final results = await searchPlaces(value);
    setState(() {
      searchSuggestions = results;
    });
  }

  void _onFromChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        fromSuggestions = [];
      });
      return;
    }
    final results = await searchPlaces(value);
    setState(() {
      fromSuggestions = results;
    });
  }

  void _onToChanged(String value) async {
    if (value.isEmpty) {
      setState(() {
        toSuggestions = [];
      });
      return;
    }
    final results = await searchPlaces(value);
    setState(() {
      toSuggestions = results;
    });
  }

  void _onSuggestionTap(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    setState(() {
      currentPosition = LatLng(lat, lon);
      route = [];
      searchController.text = place['display_name'];
      searchSuggestions = [];
      showSearchBar = false;
      showChoiceButtons = false;
    });
    mapController.move(LatLng(lat, lon), 15);
  }

  void _onFromSuggestionTap(Map<String, dynamic> place) {
    fromController.text = place['display_name'];
    fromSuggestions = [];
  }

  void _onToSuggestionTap(Map<String, dynamic> place) {
    toController.text = place['display_name'];
    toSuggestions = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demo MAPS", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43EA2E), Color(0xFFFFE600), Color(0xFFFF2D2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentPosition ?? LatLng(4.043999, 9.722999), // Coordonnées par défaut, au coeur de Douala
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
              ),
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Chemin parcouru
                    if (currentPosition != null)
                      Polyline(
                        points: route.takeWhile((p) => p != currentPosition).toList() + [currentPosition!],
                        strokeWidth: 4,
                        color: Colors.blueGrey,
                      ),
                    // Chemin restant
                    if (currentPosition != null)
                      Polyline(
                        points: route.skipWhile((p) => p != currentPosition).toList(),
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                  ],
                ),
              if (currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 15),
                    )
                  ],
                ),
            ],
          ),

          // Barre de recherche pour "Trouver un lieu"
          if (showSearchBar)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Rechercher un lieu...",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  if (searchSuggestions.isNotEmpty)
                    Container(
                      color: Colors.white,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = searchSuggestions[index];
                          return ListTile(
                            title: Text(place['display_name']),
                            onTap: () => _onSuggestionTap(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Barres de recherche pour "Itinéraire"
          if (showRouteBars)
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  TextField(
                    controller: fromController,
                    decoration: const InputDecoration(
                      hintText: "Départ",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _onFromChanged,
                  ),
                  if (fromSuggestions.isNotEmpty)
                    Container(
                      color: Colors.white,
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: fromSuggestions.length,
                        itemBuilder: (context, index) {
                          if (index < 0 || index >= fromSuggestions.length) {
                            return const SizedBox.shrink(); // Sécurité anti RangeError
                          }
                          final place = fromSuggestions[index];
                          return ListTile(
                            title: Text(place['display_name']),
                            onTap: () {
                              _onFromSuggestionTap(place);
                              FocusScope.of(context).nextFocus();
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: toController,
                    decoration: const InputDecoration(
                      hintText: "Destination",
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _onToChanged,
                  ),
                  if (toSuggestions.isNotEmpty)
                    Container(
                      color: Colors.white,
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: toSuggestions.length,
                        itemBuilder: (context, index) {
                          final place = toSuggestions[index];
                          return ListTile(
                            title: Text(place['display_name']),
                            onTap: () {
                              _onToSuggestionTap(place);
                              // Optionnel: lancer la recherche d'itinéraire automatiquement
                              _getRoute();
                              showRouteBars = false;
                              showChoiceButtons = false;
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.alt_route),
                    label: const Text("Afficher l'itinéraire"),
                    onPressed: () {
                      _getRoute();
                      showRouteBars = false;
                      showChoiceButtons = false;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

          // Boutons de choix après le bouton flottant
          if (showChoiceButtons)
            Positioned(
              bottom: 100,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: "findPlace",
                    icon: const Icon(Icons.search),
                    label: const Text("Trouver un lieu"),
                    onPressed: () {
                      setState(() {
                        showSearchBar = true;
                        showRouteBars = false;
                        showChoiceButtons = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(
                    heroTag: "route",
                    icon: const Icon(Icons.alt_route),
                    label: const Text("Itinéraire"),
                    onPressed: () {
                      setState(() {
                        showRouteBars = true;
                        showSearchBar = false;
                        showChoiceButtons = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Bouton flottant principal
          Positioned(
            bottom: 30,
            right: 30,
            child: Visibility(
              visible: !showChoiceButtons && !showSearchBar && !showRouteBars,
              child: FloatingActionButton.extended(
                heroTag: "mainFab",
                icon: const Icon(Icons.my_location, color: Colors.yellow),
                backgroundColor: Colors.red,
                label: const Text("Localisation", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() {
                    showChoiceButtons = true;
                  });
                },
              ),
            ),
          ),

          // Boutons de simulation (affichés si une route existe)
          if (route.isNotEmpty)
            Positioned(
              bottom: 80, // Décale pour laisser la place au slider
              left: 20,
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(isSimulating ? Icons.pause : Icons.play_arrow),
                        label: Text(isSimulating ? "Pause" : "Simuler"),
                        onPressed: isSimulating
                            ? () {
                                _timer?.cancel();
                                setState(() => isSimulating = false);
                              }
                            : _simulateMovement,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Réinitialiser"),
                        onPressed: () {
                          _timer?.cancel();
                          setState(() {
                            route = [];
                            currentPosition = null;
                            isSimulating = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("Vitesse:"),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          min: 100,
                          max: 1000,
                          divisions: 9,
                          value: simulationSpeed,
                          label: "${(1000 / simulationSpeed).toStringAsFixed(1)} pts/sec",
                          onChanged: (value) {
                            setState(() {
                              simulationSpeed = value;
                            });
                            if (isSimulating) {
                              _simulateMovement(); // Redémarre avec la nouvelle vitesse
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
