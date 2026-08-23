import 'package:flutter_test/flutter_test.dart';
import 'package:iliving/models/kml_model.dart';
import 'package:iliving/services/kml_parser_service.dart';

void main() {
  group('KmlParserService Tests', () {
    test('Parse simple Point Placemark', () {
      const kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>Main Gate</name>
      <description>Security Entrance checkpoint</description>
      <Point>
        <coordinates>30.9810,29.9801,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';

      final placemarks = KmlParserService.instance.parse(kml);
      expect(placemarks.length, 1);
      expect(placemarks.first.name, 'Main Gate');
      expect(placemarks.first.description, 'Security Entrance checkpoint');
      expect(placemarks.first.geometryType, KmlGeometryType.point);
      expect(placemarks.first.coordinates.length, 1);
      expect(placemarks.first.coordinates.first.latitude, 29.9801);
      expect(placemarks.first.coordinates.first.longitude, 30.9810);
    });

    test('Parse Polygon Placemark with formatting', () {
      const kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>Clubhouse Zone</name>
      <description>Zoning boundary</description>
      <fillColor>#40ECC56C</fillColor>
      <strokeColor>#ECC56C</strokeColor>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              30.9800,29.9810,0
              30.9820,29.9810,0
              30.9825,29.9830,0
              30.9800,29.9810,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';

      final placemarks = KmlParserService.instance.parse(kml);
      expect(placemarks.length, 1);
      final pm = placemarks.first;
      expect(pm.name, 'Clubhouse Zone');
      expect(pm.geometryType, KmlGeometryType.polygon);
      expect(pm.coordinates.length, 4);
      expect(pm.fillColorHex, '#40ECC56C');
      expect(pm.strokeColorHex, '#ECC56C');
      expect(pm.coordinates[0].latitude, 29.9810);
      expect(pm.coordinates[0].longitude, 30.9800);
      expect(pm.coordinates[2].latitude, 29.9830);
      expect(pm.coordinates[2].longitude, 30.9825);
    });

    test('Load mock compound coordinates', () {
      final kml = KmlParserService.instance.getMockKmlForCompound('dev_1');
      final placemarks = KmlParserService.instance.parse(kml);
      expect(placemarks.isNotEmpty, true);
      
      final points = placemarks.where((p) => p.geometryType == KmlGeometryType.point);
      final polygons = placemarks.where((p) => p.geometryType == KmlGeometryType.polygon);
      final lines = placemarks.where((p) => p.geometryType == KmlGeometryType.lineString);
      
      expect(points.length, 2);
      expect(polygons.length, 2);
      expect(lines.length, 1);
    });
  });
}
