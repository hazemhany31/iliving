class Point2D {
  final double latitude;
  final double longitude;

  const Point2D(this.latitude, this.longitude);

  @override
  String toString() => '($latitude, $longitude)';
}

enum KmlGeometryType { point, lineString, polygon, unknown }

class KmlPlacemark {
  final String name;
  final String description;
  final KmlGeometryType geometryType;
  final List<Point2D> coordinates;
  final String? fillColorHex; // Optional visual overrides
  final String? strokeColorHex;

  const KmlPlacemark({
    required this.name,
    required this.description,
    required this.geometryType,
    required this.coordinates,
    this.fillColorHex,
    this.strokeColorHex,
  });

  factory KmlPlacemark.fromJson(Map<String, dynamic> json) {
    final coordsList = json['coordinates'] as List<dynamic>? ?? [];
    final parsedCoords = coordsList.map((e) {
      final map = e as Map<String, dynamic>;
      return Point2D(map['lat'] as double, map['lng'] as double);
    }).toList();

    return KmlPlacemark(
      name: json['name'] as String? ?? 'Unnamed Zone',
      description: json['description'] as String? ?? '',
      geometryType: KmlGeometryType.values.firstWhere(
        (e) => e.name == json['geometryType'],
        orElse: () => KmlGeometryType.unknown,
      ),
      coordinates: parsedCoords,
      fillColorHex: json['fillColorHex'] as String?,
      strokeColorHex: json['strokeColorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'geometryType': geometryType.name,
      'coordinates': coordinates.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      'fillColorHex': fillColorHex,
      'strokeColorHex': strokeColorHex,
    };
  }
}
