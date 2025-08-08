import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/poi_service.dart';
import '../models/poi_model.dart';

final poiServiceProvider = Provider<POIService>((ref) {
  return POIService();
});

final nearbyPOIsProvider = FutureProvider.family<List<PointOfInterest>, Position>((ref, position) async {
  final poiService = ref.read(poiServiceProvider);
  return await poiService.findNearbyPOIs(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

final mostInterestingPOIProvider = FutureProvider.family<PointOfInterest?, Position>((ref, position) async {
  final poiService = ref.read(poiServiceProvider);
  return await poiService.findMostInterestingNearbyPOI(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});

final poiDetailsProvider = FutureProvider.family<PoiDetailsResponse?, String>((ref, xid) async {
  final poiService = ref.read(poiServiceProvider);
  return await poiService.getPOIDetails(xid);
});
