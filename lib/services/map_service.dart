import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/event.dart';

class MapService {
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371; 
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

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

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

  List<LatLng> generateRoute(LatLng start, LatLng end) {
    final int steps = 10; 
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

  double estimatedTravelTime(
      List<LatLng> routePoints, String transportProfile) {
    double speedKmH;

    switch (transportProfile) {
      case "driving-car":
        speedKmH = 50.0; 
        break;
      case "cycling-regular":
        speedKmH = 15.0; 
        break;
      case "foot-walking":
        speedKmH = 5.0; 
        break;
      default:
        speedKmH = 5.0; 
    }

    double totalDistanceKm = 0.0;

    for (int i = 0; i < routePoints.length - 1; i++) {
      totalDistanceKm += calculateDistance(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    return ((totalDistanceKm / speedKmH) * 60).roundToDouble();
  }

  Future<Map<String, dynamic>> getRoute(
      LatLng start, LatLng end, String transportProfile) async {

    final int steps = 10; 
    final double latStep = (end.latitude - start.latitude) / steps;
    final double lonStep = (end.longitude - start.longitude) / steps;

    List<LatLng> route = [];
    for (int i = 0; i <= steps; i++) {
      route.add(LatLng(
        start.latitude + (latStep * i),
        start.longitude + (lonStep * i),
      ));
    }

    double totalDistanceKm = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistanceKm += calculateDistance(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }

    double speedKmH;
    switch (transportProfile) {
      case "driving-car":
        speedKmH = 30.0; 
        break;
      case "cycling-regular":
        speedKmH = 15.0; 
        break;
      case "foot-walking":
        speedKmH = 5.0;
        break;
      default:
        speedKmH = 5.0; 
    }

    double travelTimeMinutes = (totalDistanceKm / speedKmH) * 60;

    return {
      "route": route, 
      "distance": totalDistanceKm, 
      "travelTime": travelTimeMinutes, 
    };
  }
}
