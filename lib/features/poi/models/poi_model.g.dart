// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointOfInterest _$PointOfInterestFromJson(Map<String, dynamic> json) =>
    PointOfInterest(
      xid: json['xid'] as String,
      name: json['name'] as String,
      kinds: json['kinds'] as String,
      point: PoiPoint.fromJson(json['point'] as Map<String, dynamic>),
      distance: (json['distance'] as num?)?.toInt(),
      rate: (json['rate'] as num?)?.toInt(),
      preview: json['preview'] as String?,
      wikipedia: json['wikipedia'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PointOfInterestToJson(PointOfInterest instance) =>
    <String, dynamic>{
      'xid': instance.xid,
      'name': instance.name,
      'kinds': instance.kinds,
      'point': instance.point,
      'distance': instance.distance,
      'rate': instance.rate,
      'preview': instance.preview,
      'wikipedia': instance.wikipedia,
      'description': instance.description,
    };

PoiPoint _$PoiPointFromJson(Map<String, dynamic> json) => PoiPoint(
  lon: (json['lon'] as num).toDouble(),
  lat: (json['lat'] as num).toDouble(),
);

Map<String, dynamic> _$PoiPointToJson(PoiPoint instance) => <String, dynamic>{
  'lon': instance.lon,
  'lat': instance.lat,
};

PoiDetailsResponse _$PoiDetailsResponseFromJson(Map<String, dynamic> json) =>
    PoiDetailsResponse(
      xid: json['xid'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      preview: json['preview'] as String?,
      wikipedia: json['wikipedia'] as String?,
      info: json['info'] as String?,
      description: json['description'] as String?,
      point: PoiPoint.fromJson(json['point'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PoiDetailsResponseToJson(PoiDetailsResponse instance) =>
    <String, dynamic>{
      'xid': instance.xid,
      'name': instance.name,
      'image': instance.image,
      'preview': instance.preview,
      'wikipedia': instance.wikipedia,
      'info': instance.info,
      'description': instance.description,
      'point': instance.point,
    };
