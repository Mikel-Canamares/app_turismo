import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

final locationStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.read(locationServiceProvider);
  return locationService.getPositionStream();
});
