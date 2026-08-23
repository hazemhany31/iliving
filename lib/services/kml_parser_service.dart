import '../models/kml_model.dart';

class KmlParserService {
  KmlParserService._internal();
  static final KmlParserService instance = KmlParserService._internal();

  /// Parses a raw KML string into a list of KmlPlacemarks.
  List<KmlPlacemark> parse(String kmlString) {
    final List<KmlPlacemark> placemarks = [];
    
    // Clean string a bit to handle line breaks within tags
    final cleanedString = kmlString.replaceAll(RegExp(r'\s*\n\s*'), ' ');

    // Match all <Placemark> blocks
    final placemarkRegex = RegExp(r'<Placemark>(.*?)</Placemark>', caseSensitive: false);
    final matches = placemarkRegex.allMatches(cleanedString);

    for (final match in matches) {
      final placemarkContent = match.group(1) ?? '';
      
      // Extract Name
      final nameRegex = RegExp(r'<name>(.*?)</name>', caseSensitive: false);
      final nameMatch = nameRegex.firstMatch(placemarkContent);
      final name = nameMatch?.group(1)?.trim() ?? 'Unnamed Placemark';

      // Extract Description
      final descRegex = RegExp(r'<description>(.*?)</description>', caseSensitive: false);
      final descMatch = descRegex.firstMatch(placemarkContent);
      final description = descMatch?.group(1)?.trim() ?? '';

      // Extract Styling Colors if available
      final fillColorRegex = RegExp(r'<fillColor>(.*?)</fillColor>', caseSensitive: false);
      final fillColorMatch = fillColorRegex.firstMatch(placemarkContent);
      final fillColor = fillColorMatch?.group(1)?.trim();

      final strokeColorRegex = RegExp(r'<strokeColor>(.*?)</strokeColor>', caseSensitive: false);
      final strokeColorMatch = strokeColorRegex.firstMatch(placemarkContent);
      final strokeColor = strokeColorMatch?.group(1)?.trim();

      // Determine Geometry and Parse Coordinates
      KmlGeometryType geometryType = KmlGeometryType.unknown;
      List<Point2D> coordinates = [];

      // 1. Check Polygon
      if (placemarkContent.toLowerCase().contains('<polygon>')) {
        geometryType = KmlGeometryType.polygon;
        coordinates = _parseCoordinateBlock(placemarkContent);
      } 
      // 2. Check LineString
      else if (placemarkContent.toLowerCase().contains('<linestring>')) {
        geometryType = KmlGeometryType.lineString;
        coordinates = _parseCoordinateBlock(placemarkContent);
      }
      // 3. Check Point
      else if (placemarkContent.toLowerCase().contains('<point>')) {
        geometryType = KmlGeometryType.point;
        coordinates = _parseCoordinateBlock(placemarkContent);
      }

      if (geometryType != KmlGeometryType.unknown && coordinates.isNotEmpty) {
        placemarks.add(KmlPlacemark(
          name: name,
          description: description,
          geometryType: geometryType,
          coordinates: coordinates,
          fillColorHex: fillColor,
          strokeColorHex: strokeColor,
        ));
      }
    }

    return placemarks;
  }

  List<Point2D> _parseCoordinateBlock(String placemarkContent) {
    final List<Point2D> points = [];
    final coordBlockRegex = RegExp(r'<coordinates>(.*?)</coordinates>', caseSensitive: false);
    final coordBlockMatch = coordBlockRegex.firstMatch(placemarkContent);
    
    if (coordBlockMatch != null) {
      final coordString = coordBlockMatch.group(1) ?? '';
      // Coordinates in KML are separated by spaces or newlines
      final coordinateTuples = coordString.trim().split(RegExp(r'\s+'));

      for (final tuple in coordinateTuples) {
        if (tuple.trim().isEmpty) continue;
        final parts = tuple.split(',');
        if (parts.length >= 2) {
          // KML coordinate order: longitude, latitude, altitude
          final double? lng = double.tryParse(parts[0].trim());
          final double? lat = double.tryParse(parts[1].trim());
          if (lat != null && lng != null) {
            points.add(Point2D(lat, lng));
          }
        }
      }
    }
    return points;
  }

  /// Retrives rich simulated KML document strings for standard compounds.
  String getMockKmlForCompound(String compoundId) {
    switch (compoundId) {
      case 'dev_1': // Sky Hills
        return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Sky Hills Layout Blueprint</name>
    <Placemark>
      <name>Main Entrance Security Gate</name>
      <description>Security checkpoint checkpoint 1 with RFID and smart camera verification.</description>
      <Point>
        <coordinates>30.98100,29.98010,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>Highline Sky Clubhouse</name>
      <description>Premium community clubhouse featuring sky lounge and infinity pool.</description>
      <Point>
        <coordinates>30.98350,29.98250,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>Villa Zone Alpha</name>
      <description>Zone containing premium detached high-altitude villas.</description>
      <fillColor>#40ECC56C</fillColor>
      <strokeColor>#ECC56C</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.98000,29.98100,0
              30.98200,29.98100,0
              30.98250,29.98300,0
              30.98050,29.98300,0
              30.98000,29.98100,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name>Sky Suites Towers (Block B)</name>
      <description>High rise luxury apartment block with custom Versace interior fittings.</description>
      <fillColor>#40D4AF37</fillColor>
      <strokeColor>#D4AF37</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.98300,29.98050,0
              30.98500,29.98050,0
              30.98500,29.98200,0
              30.98300,29.98200,0
              30.98300,29.98050,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name>Sky Hills Central Promenade</name>
      <description>Main green pathway connecting the compound facilities.</description>
      <LineString>
        <coordinates>
          30.98100,29.98010,0
          30.98250,29.98150,0
          30.98350,29.98250,0
        </coordinates>
      </LineString>
    </Placemark>
  </Document>
</kml>''';

      case 'dev_2': // Lamar Compound
        return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Lamar Compound Masterplan</name>
    <Placemark>
      <name>Zayed North Security Gate</name>
      <description>Main vehicle security entrance.</description>
      <Point>
        <coordinates>30.80100,30.01000,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>Lamar Central Park</name>
      <description>Large central green area and lakes.</description>
      <fillColor>#402E7D32</fillColor>
      <strokeColor>#2E7D32</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.80200,30.01100,0
              30.80500,30.01100,0
              30.80500,30.01400,0
              30.80200,30.01400,0
              30.80200,30.01100,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name>Lamar Plaza &amp; Retail</name>
      <description>Commercial area with boutiques and restaurants.</description>
      <fillColor>#40AA7C11</fillColor>
      <strokeColor>#AA7C11</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.80600,30.01000,0
              30.80800,30.01000,0
              30.80800,30.01200,0
              30.80600,30.01200,0
              30.80600,30.01000,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';

      case 'dev_3': // Zayed Lagoons
      default:
        return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Zayed Lagoons Marina Blueprint</name>
    <Placemark>
      <name>Marina Entry Gate</name>
      <description>Secure gate checkpoint for residents and yacht guests.</description>
      <Point>
        <coordinates>30.77100,29.99000,0</coordinates>
      </Point>
    </Placemark>
    <Placemark>
      <name>West Yacht Club &amp; Marina</name>
      <description>Exclusive marina harbor for boat docking.</description>
      <fillColor>#400288D1</fillColor>
      <strokeColor>#0288D1</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.77200,29.99100,0
              30.77600,29.99100,0
              30.77600,29.99400,0
              30.77200,29.99400,0
              30.77200,29.99100,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    <Placemark>
      <name>Waterfront Lagoon Villas</name>
      <description>Exclusive lagoon front residential strip.</description>
      <fillColor>#40D4AF37</fillColor>
      <strokeColor>#D4AF37</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.77700,29.99000,0
              30.78000,29.99000,0
              30.78000,29.99300,0
              30.77700,29.99300,0
              30.77700,29.99000,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';
    }
  }
}
