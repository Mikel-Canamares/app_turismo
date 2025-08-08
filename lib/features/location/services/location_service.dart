import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Getter para la última posición conocida
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Obtiene la ubicación actual con manejo robusto de errores
  Future<Position?> getCurrentLocation() async {
    try {
      print('📍 Obteniendo ubicación actual...');
      
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Los servicios de ubicación están deshabilitados');
        // Intentar abrir configuración de ubicación
        await Geolocator.openLocationSettings();
        return null;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Permiso de ubicación actual: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('🔐 Permiso después de solicitar: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ Permisos de ubicación denegados');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permisos de ubicación permanentemente denegados');
        await Geolocator.openAppSettings();
        return null;
      }

      // Obtener ubicación actual con timeout
      print('🔍 Obteniendo coordenadas GPS...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      print('✅ Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      print('   Precisión: ${position.accuracy}m, Altitud: ${position.altitude}m');
      
      return position;
      
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      
      // Intentar obtener la última ubicación conocida
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('📍 Usando última ubicación conocida: ${lastPosition.latitude}, ${lastPosition.longitude}');
          _lastKnownPosition = lastPosition;
          return lastPosition;
        }
      } catch (e2) {
        print('❌ Error obteniendo última ubicación conocida: $e2');
      }
      
      return null;
    }
  }

  Future<double> getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Inicia el stream de posiciones para seguimiento continuo
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // metros
    Duration? timeInterval,
  }) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeInterval,
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Inicia el seguimiento continuo de ubicación
  void startLocationTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onError,
  }) {
    _positionStreamSubscription?.cancel();
    
    _positionStreamSubscription = getPositionStream().listen(
      (Position position) {
        _lastKnownPosition = position;
        print('📍 Ubicación actualizada: ${position.latitude}, ${position.longitude}');
        onLocationUpdate?.call(position);
      },
      onError: (error) {
        print('❌ Error en stream de ubicación: $error');
        onError?.call(error.toString());
      },
    );
  }

  /// Detiene el seguimiento de ubicación
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    print('🛑 Seguimiento de ubicación detenido');
  }

  /// Verifica si el servicio de ubicación está habilitado
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verifica permisos de ubicación
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Solicita permisos de ubicación
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Abre la configuración de ubicación del dispositivo
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abre la configuración de la aplicación
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Calcula la distancia entre dos puntos en metros
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Obtiene la dirección aproximada basada en coordenadas
  String getApproximateAddress(Position position) {
    // Esta es una aproximación simple, para una implementación completa
    // se podría usar geocoding
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, '
           'Lng: ${position.longitude.toStringAsFixed(6)}';
  }

  /// Verifica si una posición está dentro de un radio específico de otra
  bool isWithinRadius(
    Position currentPosition,
    double targetLatitude,
    double targetLongitude,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    
    return distance <= radiusInMeters;
  }

  /// Limpia recursos
  void dispose() {
    stopLocationTracking();
    _lastKnownPosition = null;
    print('🗑️ LocationService disposed');
  }
}
