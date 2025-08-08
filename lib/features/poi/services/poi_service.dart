import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/utils/constants.dart';
import '../models/poi_model.dart';

class POIService {
  static final POIService _instance = POIService._internal();
  factory POIService() => _instance;
  POIService._internal();

  String get _apiKey => dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';

  Future<List<PointOfInterest>> findNearbyPOIs({
    required double latitude,
    required double longitude,
    int radius = AppConstants.defaultSearchRadius,
    int limit = AppConstants.maxPlacesLimit,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        print('API Key de OpenTripMap no configurada');
        return [];
      }

      // Construir URL para búsqueda de POIs
      final url = Uri.parse(
        '${AppConstants.openTripMapBaseUrl}/en/places/radius'
        '?radius=$radius'
        '&lon=$longitude'
        '&lat=$latitude'
        '&kinds=interesting_places,museums,churches,monuments,architecture,parks'
        '&format=json'
        '&limit=$limit'
        '&apikey=$_apiKey'
      );

      print('Consultando POIs en: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final List<PointOfInterest> pois = data
            .map((json) => PointOfInterest.fromJson(json))
            .where((poi) => poi.name.isNotEmpty)
            .toList();

        // Ordenar por distancia si está disponible
        pois.sort((a, b) {
          if (a.distance != null && b.distance != null) {
            return a.distance!.compareTo(b.distance!);
          }
          return 0;
        });

        print('Encontrados ${pois.length} POIs');
        return pois;
      } else {
        print('Error en API OpenTripMap: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error buscando POIs: $e');
      return [];
    }
  }

  Future<PoiDetailsResponse?> getPOIDetails(String xid) async {
    try {
      if (_apiKey.isEmpty) {
        return null;
      }

      final url = Uri.parse(
        '${AppConstants.openTripMapBaseUrl}/en/places/xid/$xid'
        '?apikey=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PoiDetailsResponse.fromJson(data);
      } else {
        print('Error obteniendo detalles del POI: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error obteniendo detalles del POI: $e');
      return null;
    }
  }

  // Método para obtener el POI más cercano e interesante
  Future<PointOfInterest?> findMostInterestingNearbyPOI({
    required double latitude,
    required double longitude,
    int radius = AppConstants.defaultSearchRadius,
  }) async {
    final pois = await findNearbyPOIs(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      limit: 10,
    );

    if (pois.isEmpty) {
      return null;
    }

    // Priorizar POIs con mejor rating o más famosos
    pois.sort((a, b) {
      // Primero por rating si está disponible
      if (a.rate != null && b.rate != null) {
        final ratingCompare = b.rate!.compareTo(a.rate!);
        if (ratingCompare != 0) return ratingCompare;
      }
      
      // Luego por tipos más interesantes
      final aScore = _getInterestScore(a.kinds);
      final bScore = _getInterestScore(b.kinds);
      final scoreCompare = bScore.compareTo(aScore);
      if (scoreCompare != 0) return scoreCompare;
      
      // Finalmente por distancia
      if (a.distance != null && b.distance != null) {
        return a.distance!.compareTo(b.distance!);
      }
      
      return 0;
    });

    return pois.first;
  }

  int _getInterestScore(String kinds) {
    int score = 0;
    if (kinds.contains('museums')) score += 10;
    if (kinds.contains('monuments')) score += 9;
    if (kinds.contains('churches')) score += 8;
    if (kinds.contains('architecture')) score += 7;
    if (kinds.contains('galleries')) score += 6;
    if (kinds.contains('theatres')) score += 5;
    if (kinds.contains('parks')) score += 4;
    if (kinds.contains('bridges')) score += 3;
    if (kinds.contains('towers')) score += 8;
    return score;
  }

  // Crear contexto descriptivo para la IA
  String createPOIContext(PointOfInterest poi, {double? userLat, double? userLon}) {
    String context = 'El usuario está cerca de: ${poi.name}. ';
    context += 'Es un ${poi.typeInSpanish}. ';
    
    if (poi.distance != null) {
      context += 'Se encuentra a ${poi.distance} metros de distancia. ';
    }
    
    if (poi.rate != null && poi.rate! > 0) {
      context += 'Tiene una puntuación de ${poi.rate} sobre 10. ';
    }
    
    context += 'Ubicado en las coordenadas ${poi.point.lat}, ${poi.point.lon}. ';
    
    return context;
  }
}
