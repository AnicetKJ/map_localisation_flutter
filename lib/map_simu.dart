import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'search_place.dart';
import 'get_route.dart';
import 'services/flutter_map_provider.dart';
import 'models/tracked_object.dart';
import 'models/route.dart';
import 'features/tracking_service.dart';
import 'features/simulation_service.dart';

class MapSimulatePage extends StatefulWidget {
  const MapSimulatePage({super.key});

  @override
  State<MapSimulatePage> createState() => _MapSimulatePageState();
}

class _MapSimulatePageState extends State<MapSimulatePage> {
  final mapController = MapController();
  LatLng? currentPosition;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  List<Map<String, dynamic>> searchSuggestions = [];
  List<Map<String, dynamic>> fromSuggestions = [];
  List<Map<String, dynamic>> toSuggestions = [];
  bool showSearchBar = false;
  bool showRouteBars = false;
  bool showChoiceButtons = false;

  late FlutterMapProvider mapProvider;
  late TrackingService trackingService;
  SimulationService? simulationService;
  RouteModel? routeModel;
  TrackedObject? trackedObject;
  Timer? _timer;
  bool isSimulating = false;
  double simulationSpeed = 500;

  @override
  void initState() {
    super.initState();
    mapProvider = FlutterMapProvider(mapController);
    trackingService = TrackingService();
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() { searchSuggestions = []; });
      return;
    }
    final results = await searchPlaces(value);
    setState(() { searchSuggestions = results; });
  }

  Future<void> _onFromChanged(String value) async {
    if (value.isEmpty) {
      setState(() { fromSuggestions = []; });
      return;
    }
    final results = await searchPlaces(value);
    setState(() { fromSuggestions = results; });
  }

  Future<void> _onToChanged(String value) async {
    if (value.isEmpty) {
      setState(() { toSuggestions = []; });
      return;
    }
    final results = await searchPlaces(value);
    setState(() { toSuggestions = results; });
  }

  void _onSuggestionTap(Map<String, dynamic> place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    setState(() {
      currentPosition = LatLng(lat, lon);
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

  Future<void> _getRoute() async {
    final from = await searchPlace(fromController.text);
    final to = await searchPlace(toController.text);
    if (from != null && to != null) {
      final newRoute = await getRoute(from, to);
      routeModel = RouteModel(newRoute);
      trackedObject = TrackedObject(id: 'car', position: newRoute.first);
      trackingService.addObject(trackedObject!);
      simulationService = SimulationService(route: routeModel!, object: trackedObject!);
      setState(() {});
      mapController.move(newRoute.first, 15);
    }
  }

  void _simulateMovement() {
    if (simulationService == null || routeModel == null) return;
    _timer?.cancel();
    simulationService!.reset();
    setState(() { isSimulating = true; });
    _timer = Timer.periodic(Duration(milliseconds: simulationSpeed.round()), (timer) {
      if (!simulationService!.nextStep()) {
        timer.cancel();
        setState(() => isSimulating = false);
        return;
      }
      setState(() {});
    });
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
              initialCenter: trackedObject?.position ?? currentPosition ?? LatLng(4.043999, 9.722999),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                
                userAgentPackageName: 'map_demo_app',
              ),
              if (routeModel != null)
                PolylineLayer(
                  polylines: [
                    if (trackedObject != null)
                      Polyline(
                        points: routeModel!.points.sublist(0, ((simulationService?.currentIndex ?? 0) + 1).clamp(0, routeModel!.points.length)),
                        strokeWidth: 4,
                        color: Colors.blueGrey,
                      ),
                    if (trackedObject != null)
                      Polyline(
                        points: routeModel!.points.sublist(((simulationService?.currentIndex ?? 0) + 1).clamp(0, routeModel!.points.length), routeModel!.points.length),
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                  ],
                ),
              if (trackedObject != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: trackedObject!.position,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 25),
                    )
                  ],
                ),
              if (currentPosition != null && trackedObject == null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 25),
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
                            title: Text(place['display_name'] ?? ''),
                            onTap: () => _onSuggestionTap(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          // Barres de recherche pour "Itinéraire"
          if (showSearchBar == false && showChoiceButtons == false && showRouteBars)
            Positioned(
              top: 100,
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
                          if (index < 0 || index >= fromSuggestions.length) return const SizedBox();
                          final place = fromSuggestions[index];
                          return ListTile(
                            title: Text(place['display_name'] ?? ''),
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
                          if (index < 0 || index >= toSuggestions.length) return const SizedBox();
                          final place = toSuggestions[index];
                          return ListTile(
                            title: Text(place['display_name'] ?? ''),
                            onTap: () {
                              _onToSuggestionTap(place);
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
          // Boutons de choix
          if (!showChoiceButtons && !showSearchBar && !showRouteBars)
            Positioned(
              bottom: 30,
              right: 30,
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
          // Boutons de simulation
          if (routeModel != null)
            Positioned(
              bottom: 80,
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
                            routeModel = null;
                            trackedObject = null;
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
                              _simulateMovement();
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
