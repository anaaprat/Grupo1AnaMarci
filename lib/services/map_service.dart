// map_service.dart
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/event.dart';

class MapService {
  // Calcular la distancia entre dos puntos en kilómetros
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    final double dLat = _degreesToRadians(endLatitude - startLatitude);
    final double dLon = _degreesToRadians(endLongitude - startLongitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLatitude)) *
            cos(_degreesToRadians(endLatitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Convertir grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Obtener eventos dentro de un radio
  List<Event> getEventsWithinRadius(
    Position currentPosition,
    List<Event> events,
    double radiusInKm,
  ) {
    return events.where((event) {
      if (event.latitude != null && event.longitude != null) {
        final distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          event.latitude!.toDouble(),
          event.longitude!.toDouble(),
        );
        return distance <= radiusInKm;
      }
      return false;
    }).toList();
  }

  // Obtener posición actual del usuario
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está deshabilitado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación han sido denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Los permisos de ubicación están permanentemente denegados.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Generar una ruta básica entre dos puntos
  List<LatLng> generateRoute(LatLng start, LatLng end) {
    final int steps = 10; // Número de puntos intermedios en la ruta
    final double latStep = (end.latitude - start.latitude) / steps;
    final double lonStep = (end.longitude - start.longitude) / steps;

    List<LatLng> route = [];
    for (int i = 0; i <= steps; i++) {
      route.add(LatLng(
        start.latitude + (latStep * i),
        start.longitude + (lonStep * i),
      ));
    }
    return route;
  }

  // Calcular el tiempo estimado de viaje
  double estimatedTravelTime(List<LatLng> routePoints) {
    // Asumir velocidad promedio de caminata: 5 km/h
    const double walkingSpeedKmH = 5.0;
    double totalDistanceKm = 0.0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistanceKm += calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    return (totalDistanceKm / walkingSpeedKmH) * 60; // Tiempo en minutos
  }

  // Obtener ruta generada manualmente
  List<LatLng> getRoute(LatLng start, LatLng end) {
    return generateRoute(start, end);
  }
}
