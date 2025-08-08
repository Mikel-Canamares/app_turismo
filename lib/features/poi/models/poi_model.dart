import 'package:json_annotation/json_annotation.dart';

part 'poi_model.g.dart';

@JsonSerializable()
class PointOfInterest {
  final String xid;
  final String name;
  final String kinds;
  @JsonKey(name: 'point')
  final PoiPoint point;
  final int? distance;
  final int? rate;
  final String? preview;
  final String? wikipedia;
  final String? description;

  const PointOfInterest({
    required this.xid,
    required this.name,
    required this.kinds,
    required this.point,
    this.distance,
    this.rate,
    this.preview,
    this.wikipedia,
    this.description,
  });

  factory PointOfInterest.fromJson(Map<String, dynamic> json) =>
      _$PointOfInterestFromJson(json);

  Map<String, dynamic> toJson() => _$PointOfInterestToJson(this);

  // Helper para obtener tipo de lugar en español
  String get typeInSpanish {
    if (kinds.contains('museums')) return 'Museo';
    if (kinds.contains('churches')) return 'Iglesia';
    if (kinds.contains('monuments')) return 'Monumento';
    if (kinds.contains('architecture')) return 'Edificio histórico';
    if (kinds.contains('parks')) return 'Parque';
    if (kinds.contains('restaurants')) return 'Restaurante';
    if (kinds.contains('theatres')) return 'Teatro';
    if (kinds.contains('galleries')) return 'Galería';
    if (kinds.contains('bridges')) return 'Puente';
    if (kinds.contains('towers')) return 'Torre';
    return 'Lugar de interés';
  }

  // Helper para crear descripción básica
  String get basicDescription {
    String desc = '$typeInSpanish llamado "$name"';
    if (distance != null) {
      desc += ' a ${distance}m de distancia';
    }
    return desc;
  }
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
