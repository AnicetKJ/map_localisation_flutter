// import 'dart:convert';
// import 'dart:async';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';

// void simulateMovement(List<LatLng> route, {double speedKmh = 40}) {
//   const updateInterval = Duration(milliseconds: 100); // animation "lente"
//   int index = 0;

//   Timer.periodic(updateInterval, (timer) {
//     if (index >= route.length) {
//       timer.cancel();
//       return;
//     }
//     setState(() {
//       currentPosition = route[index];
//     });
//     index += 1; // ou calculer selon la distance et la vitesse
//   });
// }
