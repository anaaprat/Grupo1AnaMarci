import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/Event.dart';
import '../../../services/user_service.dart';

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

  // Perfil de transporte seleccionado (coche, bicicleta, caminando, etc.)
  String _transportProfile =
      "driving-car"; // Otras opciones: "cycling-regular", "foot-walking"

  // URL de la API de OpenRouteService
  final String _routeUrl = 'https://api.openrouteservice.org/v2/directions/';

  // Tu API Key de OpenRouteService
  final String _apiKey =
      '5b3ce3597851110001cf62481384cfa99d1d4927b5d7df80de7f8eb5';

  List<LatLng> _route = [];
  bool _routeVisible = false;

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

  // Función para obtener la ruta usando OpenRouteService
  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) return;

    final origin =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    // Construimos la URL de la API con el perfil seleccionado
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

        // Verificamos si la respuesta contiene la ruta esperada
        if (data != null &&
            data['features'] != null &&
            data['features'].isNotEmpty) {
          final route = data['features'][0]['geometry']['coordinates'] as List;
          setState(() {
            _route = route.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
            _routeVisible =
                true; // Hacer visible la ruta al presionar "Cómo llegar"
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

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: FutureBuilder<List<Event>>(
        future: _eventosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar eventos: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay eventos disponibles'));
          } else {
            List<Event> eventos = snapshot.data!;

            return FlutterMap(
              mapController:
                  _mapController, //________________________________________________________________________
              options: MapOptions(
                center: LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
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
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      builder: (ctx) => Icon(
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 40.0,
                      ),
                    ),
                    ...eventos.map((evento) {
                      return Marker(
                        point: LatLng(
                            evento.latitude ?? 0.0, evento.longitude ?? 0.0),
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            _showEventDetails(context, evento);
                          },
                          child: Icon(
                            Icons.event,
                            color: Colors.red,
                            size: 40.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
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
              ],
            );
          }
        },
      ),
    );
  }

  // Función para mostrar los detalles del evento
  void _showEventDetails(BuildContext context, Event evento) {
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    evento.title ?? 'Evento sin nombre',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  if (evento.image_url != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child:
                          Image.network(evento.image_url!, fit: BoxFit.cover),
                    ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
