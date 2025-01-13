import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';
import '../services/user_service.dart';
import '../models/event.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  final String token;
  final List<Event> events;

  const MapScreen({Key? key, required this.token, required this.events})
      : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService mapService = MapService();
  late UserService userService;
  List<Event> nearbyEvents = [];
  LatLng? currentPosition;

  @override
  void initState() {
    super.initState();
    userService = UserService(token: widget.token);
    _requestLocationPermission().then((_) => _initializeMap());
  }

  Future<void> _initializeMap() async {
    try {
      final position = await mapService.getCurrentPosition();
      final eventsWithinRadius =
          mapService.getEventsWithinRadius(position, widget.events, 2.0);

      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
        nearbyEvents = eventsWithinRadius;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el mapa: $e')),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings(); // Abre la configuración para que el usuario habilite permisos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: currentPosition,
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: nearbyEvents.map((event) {
                    return Marker(
                      point: LatLng(event.latitude!.toDouble(),
                          event.longitude!.toDouble()),
                      width: 40,
                      height: 40,
                      builder: (ctx) => GestureDetector(
                        onTap: () => _showEventDetails(event),
                        child: const Icon(
                          Icons.location_on,
                          size: 40.0,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.description ?? 'Sin descripción'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Lógica para mostrar el camino (puedes usar un paquete como 'url_launcher' para abrir Google Maps)
                },
                child: const Text('Ir'),
              ),
            ],
          ),
        );
      },
    );
  }
}
