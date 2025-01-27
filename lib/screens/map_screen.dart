import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/Event.dart';
import '../../../services/user_service.dart';
import '../../../services/map_service.dart'; // Incluye MapService

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
  final String token;

  const MapScreen({required this.token});
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  final Location _locationService = Location();
  late final MapController _mapController;
  late Future<List<Event>> _eventosFuture;
  late UserService userService;

  // Perfil de transporte seleccionado (coche, bicicleta, andando)
  String _transportProfile = "driving-car"; // Perfil por defecto
  final MapService _mapService = MapService();

  // URL de la API de OpenRouteService
  final String _routeUrl = 'https://api.openrouteservice.org/v2/directions/';
  final String _apiKey =
      '5b3ce3597851110001cf62481384cfa99d1d4927b5d7df80de7f8eb5';

  List<LatLng> _route = [];
  bool _routeVisible = false;
  String _travelTime = ""; // Tiempo estimado de viaje

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
    userService = UserService(token: widget.token);
    _eventosFuture = userService.getAllEventsMap();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted =
          await _locationService.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final location = await _locationService.getLocation();
      setState(() {
        _currentLocation = location;
      });

      if (_currentLocation != null) {
        _mapController.move(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          13.0,
        );
      }
    } catch (e) {
      print("Error al obtener la ubicación: $e");
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    final origin =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    final url = Uri.parse('$_routeUrl$_transportProfile/geojson');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _apiKey,
      },
      body: json.encode({
        "coordinates": [
          [origin.longitude, origin.latitude],
          [destination.longitude, destination.latitude]
        ],
        "format": "geojson",
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data != null &&
            data['features'] != null &&
            data['features'].isNotEmpty) {
          final route = data['features'][0]['geometry']['coordinates'] as List;
          setState(() {
            _route = route.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
            _routeVisible = true;

            // Calcula el tiempo estimado de viaje
            double time =
                _mapService.estimatedTravelTime(_route, _transportProfile);
            _travelTime = "${time.toStringAsFixed(2)} minutos";
          });
        } else {
          print('No se pudo obtener una ruta válida');
        }
      } catch (e) {
        print('Error al procesar la respuesta de la API: $e');
      }
    } else {
      print('Error al obtener la ruta: ${response.statusCode}');
    }
  }

  void _updateTransportProfile(String profile, LatLng destination) {
    setState(() {
      _transportProfile = profile;
    });

    // Recalcular la ruta con la nueva opción
    _getRoute(destination);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Error al cargar eventos: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay eventos disponibles'));
                } else {
                  List<Event> eventos = snapshot.data!;
                  Map<String, List<Event>> groupedEvents = {};

                  // Agrupar eventos por coordenadas
                  for (var evento in eventos) {
                    String key = "${evento.latitude},${evento.longitude}";
                    if (!groupedEvents.containsKey(key)) {
                      groupedEvents[key] = [];
                    }
                    groupedEvents[key]!.add(evento);
                  }

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      zoom: 13.0,
                      maxZoom: 18.0,
                      minZoom: 5.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      if (_routeVisible)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route,
                              strokeWidth: 4.0,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          // Marcador para la ubicación del usuario
                          if (_currentLocation != null)
                            Marker(
                              point: LatLng(
                                _currentLocation!.latitude!,
                                _currentLocation!.longitude!,
                              ),
                              builder: (ctx) => Icon(
                                Icons.person_pin_circle,
                                color: Colors.blueAccent,
                                size: 50.0,
                              ),
                            ),
                          // Marcadores para eventos
                          ...groupedEvents.entries.map((entry) {
                            final eventsAtLocation = entry.value;
                            final firstEvent = eventsAtLocation.first;
                            final position = LatLng(
                              firstEvent.latitude ?? 0.0,
                              firstEvent.longitude ?? 0.0,
                            );

                            return Marker(
                              point: position,
                              builder: (ctx) => GestureDetector(
                                onTap: () {
                                  if (eventsAtLocation.length > 1) {
                                    _showGroupedEvents(
                                        context, eventsAtLocation);
                                  } else {
                                    _showEventDetails(context, firstEvent);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(8.0),
                                  child: eventsAtLocation.length > 1
                                      ? Text(
                                          '${eventsAtLocation.length}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          if (_routeVisible)
            Container(
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _transportProfile,
                    dropdownColor: Colors.purple[100],
                    onChanged: (value) {
                      if (value != null) {
                        LatLng destination =
                            _route.last; // Cambia según tu lógica
                        _updateTransportProfile(value, destination);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: "driving-car",
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.purple),
                            SizedBox(width: 8),
                            Text("Coche"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "cycling-regular",
                        child: Row(
                          children: [
                            Icon(Icons.directions_bike, color: Colors.purple),
                            SizedBox(width: 8),
                            Text("Bicicleta"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "foot-walking",
                        child: Row(
                          children: [
                            Icon(Icons.directions_walk, color: Colors.purple),
                            SizedBox(width: 8),
                            Text("Andando"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Tiempo estimado:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _travelTime,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.purple[900],
                          fontWeight: FontWeight.bold,
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

  void _showGroupedEvents(BuildContext context, List<Event> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (ctx, index) {
                final evento = events[index];
                return ListTile(
                  title: Text(evento.title),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showEventDetails(context, evento);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEventDetails(BuildContext context, Event evento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Container(
            width: double.infinity, // Ocupa todo el ancho disponible
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Centra los elementos horizontalmente
                children: [
                  Text(
                    evento.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  if (evento.image_url != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        evento.image_url!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centra los botones horizontalmente
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _getRoute(
                              LatLng(evento.latitude!, evento.longitude!));
                        },
                        child: Text('Cómo llegar'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: Text('Cerrar'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
