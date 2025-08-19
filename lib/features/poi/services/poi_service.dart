import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/poi_model.dart';

class POIService {
  static final POIService _instance = POIService._internal();
  factory POIService() => _instance;
  POIService._internal();

  final String _baseUrl = 'https://api.geoapify.com/v2';
  late final String _apiKey;

  /// Inicializa el servicio con la API key
  void initialize() {
    try {
      _apiKey = dotenv.env['GEOAPIFY_API_KEY'] ?? '';
      if (_apiKey.isEmpty) {
        print('⚠️ ADVERTENCIA: API key de Geoapify no encontrada en .env');
      } else {
        print('✅ POI Service inicializado con API key de Geoapify');
      }
    } catch (e) {
      print('⚠️ Error inicializando POI Service: $e');
      _apiKey = '';
    }
  }

  /// Busca lugares de interés cerca de una ubicación específica
  Future<List<PointOfInterest>> findNearbyPOIs({
    required double latitude,
    required double longitude,
    int radius = 1000, // metros
    int limit = 20,
    String categories = 'tourism.attraction,leisure.park,cultural.museum,historic,architecture', // Categorías por defecto
  }) async {
    try {
      if (_apiKey.isEmpty) {
        print('❌ No se puede buscar POIs: API key no configurada');
        return [];
      }

      print('🔍 Buscando POIs cerca de $latitude, $longitude (radio: ${radius}m)...');

      // Construir URL de búsqueda para Geoapify Places API
      final uri = Uri.parse('$_baseUrl/places')
          .replace(queryParameters: {
        'categories': categories,
        'filter': 'circle:$longitude,$latitude,$radius',
        'limit': limit.toString(),
        'apiKey': _apiKey,
      });

      print('🌐 URL de búsqueda Geoapify: $uri');

      // Realizar petición HTTP
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout en búsqueda de POIs');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📊 Respuesta Geoapify: ${response.body.length} caracteres');
        
        if (jsonData is Map && jsonData.containsKey('features')) {
          final features = jsonData['features'] as List;
          print('✅ Encontrados ${features.length} POIs');
          
          final pois = <PointOfInterest>[];
          
          for (final feature in features) {
            try {
              final poi = _parseGeoapifyFeatureToPOI(feature, latitude, longitude);
              if (poi != null) {
                pois.add(poi);
                print('📍 POI encontrado: ${poi.name} a ${poi.distance.toStringAsFixed(0)}m (${poi.category})');
              }
            } catch (e) {
              print('⚠️ Error parseando POI: $e');
            }
          }
          
          // Ordenar por distancia
          pois.sort((a, b) => a.distance.compareTo(b.distance));
          
          print('📍 POIs procesados: ${pois.length}');
          if (pois.isNotEmpty) {
            print('🎯 POI más cercano: ${pois.first.name} a ${pois.first.distance.toStringAsFixed(0)}m');
            print('🎯 POI más lejano: ${pois.last.name} a ${pois.last.distance.toStringAsFixed(0)}m');
          }
          return pois;
          
        } else {
          print('⚠️ Formato de respuesta inesperado de Geoapify');
          return [];
        }
      } else {
        print('❌ Error en API Geoapify: ${response.statusCode} - ${response.body}');
        return [];
      }
      
    } catch (e) {
      print('❌ Error buscando POIs: $e');
      return [];
    }
  }

  /// Obtiene detalles completos de un POI específico
  Future<PointOfInterest?> getPOIDetails(String placeId) async {
    try {
      if (_apiKey.isEmpty) {
        print('❌ No se pueden obtener detalles: API key no configurada');
        return null;
      }

      print('🔍 Obteniendo detalles del POI: $placeId');

      final uri = Uri.parse('$_baseUrl/places/details')
          .replace(queryParameters: {
        'place_id': placeId,
        'apiKey': _apiKey,
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout obteniendo detalles del POI');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Detalles obtenidos para POI $placeId');
        
        return _parseGeoapifyDetailsToPOI(jsonData);
      } else {
        print('❌ Error obteniendo detalles: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error obteniendo detalles del POI: $e');
      return null;
    }
  }

  /// Encuentra el POI más interesante cerca de una ubicación
  Future<PointOfInterest?> findMostInterestingNearbyPOI({
    required double latitude,
    required double longitude,
    int radius = 1000,
  }) async {
    try {
      print('🎯 Buscando el POI más interesante...');
      
      // Buscar POIs con diferentes categorías priorizando los más interesantes
      final categories = [
        'tourism.attraction,cultural.museum,historic',
        'leisure.park,entertainment',
        'architecture,religion',
        'sport,food',
      ];

      for (final category in categories) {
        final pois = await findNearbyPOIs(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          limit: 10,
          categories: category,
        );

        if (pois.isNotEmpty) {
          // Tomar el más cercano de la categoría más prioritaria
          final bestPOI = pois.first;
          print('🎯 POI más interesante encontrado: ${bestPOI.name} (${bestPOI.distance.toStringAsFixed(0)}m)');
          
          // Obtener detalles completos
          if (bestPOI.xid.isNotEmpty) {
            final detailedPOI = await getPOIDetails(bestPOI.xid);
            if (detailedPOI != null) {
              return detailedPOI;
            }
          }
          
          return bestPOI;
        }
      }

      print('⚠️ No se encontraron POIs interesantes en el área');
      return null;
      
    } catch (e) {
      print('❌ Error buscando POI más interesante: $e');
      return null;
    }
  }

  /// Crea contexto descriptivo sobre un POI para la IA
  String createPOIContext(PointOfInterest poi, Position userPosition) {
    final distanceText = poi.distance < 1000 
        ? '${poi.distance.toStringAsFixed(0)} metros'
        : '${(poi.distance / 1000).toStringAsFixed(1)} kilómetros';

    final context = StringBuffer();
    context.writeln('Información sobre el lugar de interés cercano:');
    context.writeln('- Nombre: ${poi.name}');
    context.writeln('- Distancia: $distanceText');
    context.writeln('- Categoría: ${poi.category}');
    
    if (poi.description.isNotEmpty) {
      context.writeln('- Descripción: ${poi.description}');
    }
    
    if (poi.address.isNotEmpty) {
      context.writeln('- Dirección: ${poi.address}');
    }
    
    context.writeln('- Ubicación del usuario: ${userPosition.latitude.toStringAsFixed(6)}, ${userPosition.longitude.toStringAsFixed(6)}');
    context.writeln('- Ubicación del POI: ${poi.latitude.toStringAsFixed(6)}, ${poi.longitude.toStringAsFixed(6)}');

    return context.toString();
  }

  /// Convierte un feature de Geoapify a PointOfInterest
  PointOfInterest? _parseGeoapifyFeatureToPOI(Map<String, dynamic> feature, double userLat, double userLon) {
    try {
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List? ?? [];

      if (coordinates.length < 2) {
        return null;
      }

      final longitude = coordinates[0]?.toDouble() ?? 0.0;
      final latitude = coordinates[1]?.toDouble() ?? 0.0;

      final distance = Geolocator.distanceBetween(userLat, userLon, latitude, longitude);

      // Extraer categorías de Geoapify
      final categories = properties['categories']?.toString() ?? '';
      final category = _extractMainCategory(categories);

      // Extraer dirección
      final address = properties['address']?.toString() ?? 
                     properties['street']?.toString() ?? 
                     properties['city']?.toString() ?? '';

      return PointOfInterest(
        id: properties['place_id']?.toString() ?? '',
        xid: properties['place_id']?.toString() ?? '',
        name: properties['name']?.toString() ?? 'Lugar sin nombre',
        latitude: latitude,
        longitude: longitude,
        category: category,
        description: properties['description']?.toString() ?? '',
        address: address,
        distance: distance,
        rating: 0.0,
        imageUrl: '',
      );
    } catch (e) {
      print('❌ Error parseando feature de Geoapify: $e');
      return null;
    }
  }

  /// Extrae la categoría principal de las categorías de Geoapify
  String _extractMainCategory(String categories) {
    if (categories.contains('tourism.attraction')) return 'tourism.attraction';
    if (categories.contains('leisure.park')) return 'leisure.park';
    if (categories.contains('cultural.museum')) return 'cultural.museum';
    if (categories.contains('historic')) return 'historic';
    if (categories.contains('architecture')) return 'architecture';
    if (categories.contains('religion')) return 'religion';
    if (categories.contains('sport')) return 'sport';
    if (categories.contains('entertainment')) return 'entertainment';
    if (categories.contains('food')) return 'food';
    if (categories.contains('shopping')) return 'shopping';
    return 'unknown';
  }

  /// Convierte un feature de OpenTripMap a PointOfInterest (mantenido para compatibilidad)
  PointOfInterest? _parseFeatureToPOI(Map<String, dynamic> feature, double userLat, double userLon) {
    try {
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List? ?? [];

      if (coordinates.length < 2) {
        return null;
      }

      final longitude = coordinates[0]?.toDouble() ?? 0.0;
      final latitude = coordinates[1]?.toDouble() ?? 0.0;

      final distance = Geolocator.distanceBetween(userLat, userLon, latitude, longitude);

      return PointOfInterest(
        id: properties['xid']?.toString() ?? '',
        xid: properties['xid']?.toString() ?? '',
        name: properties['name']?.toString() ?? 'Lugar sin nombre',
        latitude: latitude,
        longitude: longitude,
        category: properties['kinds']?.toString() ?? 'unknown',
        description: '',
        address: '',
        distance: distance,
        rating: 0.0,
        imageUrl: '',
      );
    } catch (e) {
      print('❌ Error parseando feature: $e');
      return null;
    }
  }

  /// Convierte detalles de Geoapify a PointOfInterest
  PointOfInterest? _parseGeoapifyDetailsToPOI(Map<String, dynamic> details) {
    try {
      final properties = details['properties'] as Map<String, dynamic>? ?? {};
      final geometry = details['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geometry['coordinates'] as List? ?? [];

      if (coordinates.length < 2) {
        return null;
      }

      final longitude = coordinates[0]?.toDouble() ?? 0.0;
      final latitude = coordinates[1]?.toDouble() ?? 0.0;

      final categories = properties['categories']?.toString() ?? '';
      final category = _extractMainCategory(categories);

      return PointOfInterest(
        id: properties['place_id']?.toString() ?? '',
        xid: properties['place_id']?.toString() ?? '',
        name: properties['name']?.toString() ?? 'Lugar sin nombre',
        latitude: latitude,
        longitude: longitude,
        category: category,
        description: properties['description']?.toString() ?? 
                    properties['wikipedia']?.toString() ?? '',
        address: properties['address']?.toString() ?? 
                properties['street']?.toString() ?? 
                properties['city']?.toString() ?? '',
        distance: 0.0, // Se calculará externamente
        rating: 0.0,
        imageUrl: properties['image']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error parseando detalles de Geoapify: $e');
      return null;
    }
  }

  /// Convierte detalles de OpenTripMap a PointOfInterest (mantenido para compatibilidad)
  PointOfInterest? _parseDetailsToPOI(Map<String, dynamic> details) {
    try {
      final point = details['point'] as Map<String, dynamic>? ?? {};
      final longitude = point['lon']?.toDouble() ?? 0.0;
      final latitude = point['lat']?.toDouble() ?? 0.0;

      return PointOfInterest(
        id: details['xid']?.toString() ?? '',
        xid: details['xid']?.toString() ?? '',
        name: details['name']?.toString() ?? 'Lugar sin nombre',
        latitude: latitude,
        longitude: longitude,
        category: details['kinds']?.toString() ?? 'unknown',
        description: details['wikipedia_extracts']?['text']?.toString() ?? 
                    details['info']?['descr']?.toString() ?? '',
        address: details['address']?['road']?.toString() ?? 
                details['address']?['city']?.toString() ?? '',
        distance: 0.0, // Se calculará externamente
        rating: details['rate']?.toDouble() ?? 0.0,
        imageUrl: details['preview']?['source']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error parseando detalles: $e');
      return null;
    }
  }
}