import 'package:json_annotation/json_annotation.dart';

part 'poi_model.g.dart';

@JsonSerializable()
class PointOfInterest {
  final String id;
  final String xid;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String description;
  final String address;
  final double distance;
  final double rating;
  final String imageUrl;

  const PointOfInterest({
    required this.id,
    required this.xid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.description,
    required this.address,
    required this.distance,
    required this.rating,
    required this.imageUrl,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      _$PointOfInterestFromJson(json);

  Map<String, dynamic> toJson() => _$PointOfInterestToJson(this);

  // Helper para obtener tipo de lugar en español
  String get typeInSpanish {
    if (category.contains('museums')) return 'Museo';
    if (category.contains('churches')) return 'Iglesia';
    if (category.contains('monuments')) return 'Monumento';
    if (category.contains('architecture')) return 'Edificio histórico';
    if (category.contains('parks')) return 'Parque';
    if (category.contains('restaurants')) return 'Restaurante';
    if (category.contains('theatres')) return 'Teatro';
    if (category.contains('galleries')) return 'Galería';
    if (category.contains('bridges')) return 'Puente';
    if (category.contains('towers')) return 'Torre';
    if (category.contains('cultural')) return 'Sitio cultural';
    if (category.contains('historic')) return 'Sitio histórico';
    if (category.contains('natural')) return 'Lugar natural';
    if (category.contains('religion')) return 'Lugar religioso';
    if (category.contains('sport')) return 'Instalación deportiva';
    if (category.contains('entertainment')) return 'Entretenimiento';
    if (category.contains('tourist_facilities')) return 'Instalación turística';
    return 'Lugar de interés';
  }

  // Helper para crear descripción básica
  String get basicDescription {
    String desc = '$typeInSpanish llamado "$name"';
    if (distance > 0) {
      if (distance < 1000) {
        desc += ' a ${distance.toStringAsFixed(0)} metros de distancia';
      } else {
        desc += ' a ${(distance / 1000).toStringAsFixed(1)} kilómetros de distancia';
      }
    }
    return desc;
  }

  // Helper para obtener una descripción detallada
  String get detailedDescription {
    final buffer = StringBuffer();
    buffer.write(basicDescription);
    
    if (description.isNotEmpty) {
      buffer.write('. $description');
    }
    
    if (address.isNotEmpty) {
      buffer.write(' Ubicado en $address.');
    }
    
    if (rating > 0) {
      buffer.write(' Tiene una valoración de ${rating.toStringAsFixed(1)} estrellas.');
    }
    
    return buffer.toString();
  }

  // Copia con modificaciones
  PointOfInterest copyWith({
    String? id,
    String? xid,
    String? name,
    double? latitude,
    double? longitude,
    String? category,
    String? description,
    String? address,
    double? distance,
    double? rating,
    String? imageUrl,
  }) {
    return PointOfInterest(
      id: id ?? this.id,
      xid: xid ?? this.xid,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      description: description ?? this.description,
      address: address ?? this.address,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'PointOfInterest(name: $name, category: $category, distance: ${distance.toStringAsFixed(0)}m)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointOfInterest && other.xid == xid;
  }

  @override
  int get hashCode => xid.hashCode;
}

@JsonSerializable()
class PoiPoint {
  final double lon;
  final double lat;

  const PoiPoint({
    required this.lon,
    required this.lat,
  });

  factory PoiPoint.fromJson(Map<String, dynamic> json) =>
      _$PoiPointFromJson(json);

  Map<String, dynamic> toJson() => _$PoiPointToJson(this);
}

@JsonSerializable()
class PoiDetailsResponse {
  final String xid;
  final String name;
  final String? image;
  final String? preview;
  final String? wikipedia;
  final String? info;
  final String? description;
  final PoiPoint point;

  const PoiDetailsResponse({
    required this.xid,
    required this.name,
    this.image,
    this.preview,
    this.wikipedia,
    this.info,
    this.description,
    required this.point,
  });

  factory PoiDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$PoiDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PoiDetailsResponseToJson(this);
}