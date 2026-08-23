import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/luxury_theme.dart';
import '../models/compound_model.dart';
import '../models/kml_model.dart';
import '../services/kml_parser_service.dart';
import '../widgets/interactive_tap_bounce.dart';

class CompoundMapScreen extends StatefulWidget {
  final CompoundModel compound;
  final bool isOperationsMode;

  const CompoundMapScreen({
    super.key,
    required this.compound,
    this.isOperationsMode = false,
  });

  @override
  State<CompoundMapScreen> createState() => _CompoundMapScreenState();
}

class _CompoundMapScreenState extends State<CompoundMapScreen> {
  List<KmlPlacemark> _placemarks = [];
  KmlPlacemark? _selectedPlacemark;

  double _minLat = 90.0;
  double _maxLat = -90.0;
  double _minLng = 180.0;
  double _maxLng = -180.0;

  @override
  void initState() {
    super.initState();
    _loadAndParseKml();
  }

  void _loadAndParseKml() {
    final kmlContent = KmlParserService.instance.getMockKmlForCompound(widget.compound.id);
    final parsed = KmlParserService.instance.parse(kmlContent);

    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;
    bool hasCoords = false;

    for (final pm in parsed) {
      for (final pt in pm.coordinates) {
        hasCoords = true;
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }
    }

    if (hasCoords) {
      final latSpan = maxLat - minLat;
      final lngSpan = maxLng - minLng;
      const paddingRatio = 0.15;

      _minLat = minLat - (latSpan > 0 ? latSpan * paddingRatio : 0.001);
      _maxLat = maxLat + (latSpan > 0 ? latSpan * paddingRatio : 0.001);
      _minLng = minLng - (lngSpan > 0 ? lngSpan * paddingRatio : 0.001);
      _maxLng = maxLng + (lngSpan > 0 ? lngSpan * paddingRatio : 0.001);
    }

    setState(() {
      _placemarks = parsed;
    });
  }

  Point2D _screenToLatLng(Offset localPosition, Size canvasSize) {
    final double lng = _minLng + (localPosition.dx / canvasSize.width) * (_maxLng - _minLng);
    final double lat = _minLat + ((canvasSize.height - localPosition.dy) / canvasSize.height) * (_maxLat - _minLat);
    return Point2D(lat, lng);
  }

  void _handleTap(TapUpDetails details, Size canvasSize) {
    final localPos = details.localPosition;
    final latLng = _screenToLatLng(localPos, canvasSize);

    KmlPlacemark? tappedPlacemark;

    double closestDist = double.infinity;
    for (final pm in _placemarks) {
      if (pm.geometryType == KmlGeometryType.point && pm.coordinates.isNotEmpty) {
        final pt = pm.coordinates.first;
        final dist = sqrt(pow(pt.latitude - latLng.latitude, 2) + pow(pt.longitude - latLng.longitude, 2));
        if (dist < 0.0006 && dist < closestDist) {
          closestDist = dist;
          tappedPlacemark = pm;
        }
      }
    }

    if (tappedPlacemark == null) {
      for (final pm in _placemarks) {
        if (pm.geometryType == KmlGeometryType.polygon) {
          if (_isPointInPolygon(latLng, pm.coordinates)) {
            tappedPlacemark = pm;
            break;
          }
        }
      }
    }

    setState(() {
      _selectedPlacemark = tappedPlacemark;
    });
  }

  bool _isPointInPolygon(Point2D point, List<Point2D> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      if (((p1.latitude > point.latitude) != (p2.latitude > point.latitude)) &&
          (point.longitude < (p2.longitude - p1.longitude) * (point.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude)) {
        intersectCount++;
      }
    }
    return intersectCount % 2 != 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.compound.title.toUpperCase()} BLUEPRINT',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapSize = Size(constraints.maxWidth, constraints.maxHeight * 0.70);

          return Stack(
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                child: GestureDetector(
                  onTapUp: (details) => _handleTap(details, mapSize),
                  child: Container(
                    width: mapSize.width,
                    height: mapSize.height,
                    color: isDark ? AppColors.darkCardAlt : const Color(0xFFEAEBED),
                    child: CustomPaint(
                      size: mapSize,
                      painter: KmlMapPainter(
                        placemarks: _placemarks,
                        selectedPlacemark: _selectedPlacemark,
                        minLat: _minLat,
                        maxLat: _maxLat,
                        minLng: _minLng,
                        maxLng: _maxLng,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : Colors.white).withAlpha(230),
                    borderRadius: AppBorderRadius.pill,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.map_rounded, color: AppColors.accent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'VECTOR KML BLUEPRINT',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: textColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildDetailsPanel(isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailsPanel(bool isDark) {
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    if (_selectedPlacemark == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: textMuted, size: 32),
            const SizedBox(height: 10),
            Text(
              'TAP MAP REGION OR MARKER',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select zones, clubhouses, or security checkpoints to inspect coordinates and specs.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final pm = _selectedPlacemark!;
    String geometryLabel = 'Checkpoint Marker';
    IconData geomIcon = Icons.location_on_rounded;
    if (pm.geometryType == KmlGeometryType.polygon) {
      geometryLabel = 'Enclosed Zone Boundary';
      geomIcon = Icons.layers_rounded;
    } else if (pm.geometryType == KmlGeometryType.lineString) {
      geometryLabel = 'Compound Path/Pathway';
      geomIcon = Icons.timeline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                  borderRadius: AppBorderRadius.pill,
                ),
                child: Row(
                  children: [
                    Icon(geomIcon, color: AppColors.accent, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      geometryLabel.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.accent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                onPressed: () => setState(() => _selectedPlacemark = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pm.name,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pm.description,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS ANCHOR POINT',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pm.coordinates.isNotEmpty
                        ? 'Lat: ${pm.coordinates.first.latitude.toStringAsFixed(5)}, Lng: ${pm.coordinates.first.longitude.toStringAsFixed(5)}'
                        : 'No Coordinates Available',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.isOperationsMode && pm.name.contains('Gate'))
                InteractiveTapBounce(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening secure video feed for: ${pm.name}...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.accent : AppColors.primary,
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'CCTV STREAM',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class KmlMapPainter extends CustomPainter {
  final List<KmlPlacemark> placemarks;
  final KmlPlacemark? selectedPlacemark;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final bool isDark;

  KmlMapPainter({
    required this.placemarks,
    required this.selectedPlacemark,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.isDark,
  });

  Offset _latLngToScreen(Point2D pt, Size size) {
    if (maxLng == minLng || maxLat == minLat) return Offset.zero;
    final double x = ((pt.longitude - minLng) / (maxLng - minLng)) * size.width;
    final double y = size.height - ((pt.latitude - minLat) / (maxLat - minLat)) * size.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(12)
      ..strokeWidth = 1.0;
    
    const int rows = 12;
    const int cols = 12;
    for (int i = 0; i <= rows; i++) {
      final double y = (size.height / rows) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i <= cols; i++) {
      final double x = (size.width / cols) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (final pm in placemarks) {
      final isSelected = selectedPlacemark == pm;

      if (pm.geometryType == KmlGeometryType.polygon && pm.coordinates.length >= 3) {
        final path = Path();
        final startOffset = _latLngToScreen(pm.coordinates.first, size);
        path.moveTo(startOffset.dx, startOffset.dy);

        for (int i = 1; i < pm.coordinates.length; i++) {
          final offset = _latLngToScreen(pm.coordinates[i], size);
          path.lineTo(offset.dx, offset.dy);
        }
        path.close();

        Color fillBaseColor = AppColors.accent;
        if (pm.fillColorHex != null) {
          fillBaseColor = _colorFromHex(pm.fillColorHex!) ?? AppColors.accent;
        }

        final fillPaint = Paint()
          ..color = fillBaseColor.withAlpha(isSelected ? 90 : 35)
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = isSelected ? AppColors.accent : fillBaseColor.withAlpha(180)
          ..strokeWidth = isSelected ? 2.5 : 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
      } else if (pm.geometryType == KmlGeometryType.lineString && pm.coordinates.length >= 2) {
        final path = Path();
        final startOffset = _latLngToScreen(pm.coordinates.first, size);
        path.moveTo(startOffset.dx, startOffset.dy);

        for (int i = 1; i < pm.coordinates.length; i++) {
          final offset = _latLngToScreen(pm.coordinates[i], size);
          path.lineTo(offset.dx, offset.dy);
        }

        final linePaint = Paint()
          ..color = isSelected
              ? AppColors.accent
              : (isDark ? AppColors.textLightMuted.withAlpha(160) : AppColors.textDarkMuted.withAlpha(160))
          ..strokeWidth = isSelected ? 4.0 : 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, linePaint);
      }
    }

    for (final pm in placemarks) {
      if (pm.geometryType == KmlGeometryType.point && pm.coordinates.isNotEmpty) {
        final isSelected = selectedPlacemark == pm;
        final offset = _latLngToScreen(pm.coordinates.first, size);

        if (isSelected) {
          final pulsePaint = Paint()
            ..color = AppColors.accent.withAlpha(60)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(offset, 18.0, pulsePaint);
        }

        final markerOuterPaint = Paint()
          ..color = isSelected ? AppColors.accent : (isDark ? AppColors.darkCardAlt : Colors.white)
          ..style = PaintingStyle.fill;
        
        final markerInnerPaint = Paint()
          ..color = isSelected ? Colors.white : AppColors.accent
          ..style = PaintingStyle.fill;

        canvas.drawCircle(offset, 7.0, markerOuterPaint);
        canvas.drawCircle(offset, 4.0, markerInnerPaint);

        final textSpan = TextSpan(
          text: pm.name,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.textLight : AppColors.textDark),
            fontSize: 7.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            backgroundColor: (isDark ? AppColors.darkBackground : Colors.white).withAlpha(180),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        
        textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - 16.0));
      }
    }
  }

  Color? _colorFromHex(String hex) {
    try {
      String cleanHex = hex.trim().replaceAll('#', '');
      if (cleanHex.length == 8) {
        final int val = int.parse(cleanHex, radix: 16);
        return Color(val);
      } else if (cleanHex.length == 6) {
        final int val = int.parse('FF$cleanHex', radix: 16);
        return Color(val);
      }
    } catch (_) {}
    return null;
  }

  @override
  bool shouldRepaint(covariant KmlMapPainter oldDelegate) {
    return oldDelegate.placemarks != placemarks ||
        oldDelegate.selectedPlacemark != selectedPlacemark ||
        oldDelegate.isDark != isDark;
  }
}
