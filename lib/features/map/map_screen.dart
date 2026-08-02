import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../data/models/line_model.dart';
import '../../data/models/polygon_model.dart';
import '../../core/theme/app_theme.dart';
import '../collection/collect_point_screen.dart';
import '../export/export_screen.dart';
import '../stakeout/stakeout_screen.dart';
import '../reports/report_screen.dart';
import '../layers/layers_screen.dart';
import '../edit/edit_point_screen.dart';

enum DrawMode { none, point, line, polygon }

class MapScreen extends StatefulWidget {
  final ProjectModel project;

  const MapScreen({super.key, required this.project});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _accuracyMode = 'single';
  bool _isLoadingLocation = true;



  // Map objects
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadMapObjects();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          18,
        ),
      );
    } else {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _loadMapObjects() {
    // Markers from points
    final markers = widget.project.points.map((point) {
      return Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.latitude, point.longitude),
        infoWindow: InfoWindow(
          title: point.name,
          snippet: '±${point.accuracy.toStringAsFixed(2)} m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditPointScreen(project: widget.project, point: point),
            ),
          );
          if (result == true) _loadMapObjects();
        },
      );
    }).toSet();

    // Polylines from lines
    final polylines = <Polyline>{};
    for (var line in widget.project.lines) {
      if (line.points.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: PolylineId(line.id),
            points: line.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            color: AppTheme.secondaryColor,
            width: 4,
          ),
        );
      }
    }

    // Polygons
    final polygons = <Polygon>{};
    for (var poly in widget.project.polygons) {
      if (poly.points.length >= 3) {
        polygons.add(
          Polygon(
            polygonId: PolygonId(poly.id),
            points: poly.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            fillColor: AppTheme.accentColor.withOpacity(0.3),
            strokeColor: AppTheme.accentColor,
            strokeWidth: 3,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
      _polygons = polygons;
    });
  }

  // ─── Collect single point ───────────────────────────────────────────────
  void _openCollectPoint() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('waiting_gps'.tr())),
      );
      return;
    }

    final result = await Navigator.push<PointModel>(
      context,
      MaterialPageRoute(
        builder: (_) => CollectPointScreen(
          project: widget.project,
          currentPosition: _currentPosition!,
          accuracyMode: _accuracyMode,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        widget.project.points.add(result);
        widget.project.updatedAt = DateTime.now();
        widget.project.save();
        _loadMapObjects();
      });
    }
  }

  // ─── Drawing helpers ────────────────────────────────────────────────────
  void _startDrawing(DrawMode mode) {
    setState(() {
      _drawMode = mode;
      _currentDrawingPoints = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == DrawMode.line
              ? 'tap_to_add_line_points'.tr()
              : 'tap_to_add_polygon_points'.tr(),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onMapTap(LatLng position) {
    if (_drawMode == DrawMode.none) return;

    setState(() {
      _currentDrawingPoints.add(position);

      // Temporary marker for drawing
      _markers = {
        ..._markers,
        Marker(
          markerId: MarkerId('temp_${_currentDrawingPoints.length}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _drawMode == DrawMode.line
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
        ),
      };

      // Temporary polyline / polygon while drawing
      if (_drawMode == DrawMode.line && _currentDrawingPoints.length >= 2) {
        _polylines = {
          ..._polylines.where((p) => p.polylineId.value != 'temp_line'),
          Polyline(
            polylineId: const PolylineId('temp_line'),
            points: List.from(_currentDrawingPoints),
            color: AppTheme.secondaryColor.withOpacity(0.7),
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      }

      if (_drawMode == DrawMode.polygon && _currentDrawingPoints.length >= 2) {
        _polygons = {
          ..._polygons.where((p) => p.polygonId.value != 'temp_polygon'),
          Polygon(
            polygonId: const PolygonId('temp_polygon'),
            points: List.from(_currentDrawingPoints),
            fillColor: AppTheme.accentColor.withOpacity(0.2),
            strokeColor: AppTheme.accentColor,
            strokeWidth: 2,
          ),
        };
      }
    });
  }

  void _finishDrawing() {
    if (_drawMode == DrawMode.line) {
      if (_currentDrawingPoints.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('need_at_least_2_points'.tr())),
        );
        return;
      }
      _saveLine();
    } else if (_drawMode == DrawMode.polygon) {
      if (_currentDrawingPoints.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('need_at_least_3_points'.tr())),
        );
        return;
      }
      _savePolygon();
    }
  }

  void _cancelDrawing() {
    setState(() {
      _drawMode = DrawMode.none;
      _currentDrawingPoints = [];
      _loadMapObjects(); // reload clean
    });
  }

  void _saveLine() {
    final points = _currentDrawingPoints.map((latLng) {
      return PointModel(
        name: 'L${widget.project.lines.length + 1}_${_currentDrawingPoints.indexOf(latLng) + 1}',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        altitude: _currentPosition?.altitude ?? 0,
        accuracy: _currentPosition?.accuracy ?? 0,
        collectionMode: _accuracyMode,
      );
    }).toList();

    double length = 0;
    for (int i = 0; i < points.length - 1; i++) {
      length += _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    final line = LineModel(
      name: 'Line ${widget.project.lines.length + 1}',
      points: points,
      length: length,
    );

    setState(() {
      widget.project.lines.add(line);
      widget.project.updatedAt = DateTime.now();
      widget.project.save();
      _drawMode = DrawMode.none;
      _currentDrawingPoints = [];
      _loadMapObjects();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${'line_saved'.tr()} • ${length.toStringAsFixed(2)} m'),
      ),
    );
  }

  void _savePolygon() {
    final points = _currentDrawingPoints.map((latLng) {
      return PointModel(
        name: 'Poly${widget.project.polygons.length + 1}_${_currentDrawingPoints.indexOf(latLng) + 1}',
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        altitude: _currentPosition?.altitude ?? 0,
        accuracy: _currentPosition?.accuracy ?? 0,
        collectionMode: _accuracyMode,
      );
    }).toList();

    final area = _calculatePolygonArea(points);
    final perimeter = _calculatePolygonPerimeter(points);

    final polygon = PolygonModel(
      name: 'Polygon ${widget.project.polygons.length + 1}',
      points: points,
      area: area,
      perimeter: perimeter,
    );

    setState(() {
      widget.project.polygons.add(polygon);
      widget.project.updatedAt = DateTime.now();
      widget.project.save();
      _drawMode = DrawMode.none;
      _currentDrawingPoints = [];
      _loadMapObjects();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${'polygon_saved'.tr()} • ${area.toStringAsFixed(1)} m² • ${perimeter.toStringAsFixed(1)} m',
        ),
      ),
    );
  }

  // Haversine distance in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  // Shoelace formula for polygon area (approx in m²)
  double _calculatePolygonArea(List<PointModel> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() / 2.0;

    // Convert degrees² to m² (rough approximation at equator)
    // Better: use local projection, but this is acceptable for MVP
    const metersPerDegree = 111320.0;
    return area * metersPerDegree * metersPerDegree;
  }

  double _calculatePolygonPerimeter(List<PointModel> points) {
    if (points.length < 2) return 0;
    double perimeter = 0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += _calculateDistance(
        points[i].latitude,
        points[i].longitude,
        points[j].latitude,
        points[j].longitude,
      );
    }
    return perimeter;
  }


  void _openStakeout() {
    if (widget.project.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_point_stakeout'.tr())),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('select_point_stakeout'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...widget.project.points.map((point) {
                return ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(point.name),
                  subtitle: Text('${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StakeoutScreen(project: widget.project, targetPoint: point),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (_drawMode != DrawMode.none) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'finish'.tr(),
              onPressed: _finishDrawing,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'cancel'.tr(),
              onPressed: _cancelDrawing,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.assessment),
              tooltip: 'report'.tr(),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(project: widget.project)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.layers),
              tooltip: 'layers'.tr(),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LayersScreen(project: widget.project)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'export'.tr(),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(project: widget.project)));
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Map
          _isLoadingLocation
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : const LatLng(30.0444, 31.2357),
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  polygons: _polygons,
                  mapType: MapType.hybrid,
                  zoomControlsEnabled: false,
                ),

          // Drawing mode banner
          if (_drawMode != DrawMode.none)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                color: _drawMode == DrawMode.line
                    ? AppTheme.secondaryColor
                    : AppTheme.accentColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _drawMode == DrawMode.line ? Icons.timeline : Icons.pentagon,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _drawMode == DrawMode.line
                              ? '${'drawing_line'.tr()} (${_currentDrawingPoints.length})'
                              : '${'drawing_polygon'.tr()} (${_currentDrawingPoints.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _finishDrawing,
                        child: Text(
                          'finish'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Accuracy mode (when not drawing)
          if (_drawMode == DrawMode.none)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _accuracyMode,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'single', child: Text('mode_single'.tr())),
                              DropdownMenuItem(value: 'base_rover', child: Text('mode_base_rover'.tr())),
                              DropdownMenuItem(value: 'external_gnss', child: Text('mode_external_gnss'.tr())),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _accuracyMode = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Current accuracy info
          if (_currentPosition != null && _drawMode == DrawMode.none)
            Positioned(
              bottom: 110,
              left: 12,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acc: ±${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Text(
                        'Alt: ${_currentPosition!.altitude.toStringAsFixed(1)} m',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom tools
          if (_drawMode == DrawMode.none)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(
                    icon: Icons.add_location_alt,
                    label: 'collect_point'.tr(),
                    color: AppTheme.primaryColor,
                    onTap: _openCollectPoint,
                  ),
                  _buildToolButton(
                    icon: Icons.timeline,
                    label: 'draw_line'.tr(),
                    color: AppTheme.secondaryColor,
                    onTap: () => _startDrawing(DrawMode.line),
                  ),
                  _buildToolButton(
                    icon: Icons.pentagon,
                    label: 'draw_polygon'.tr(),
                    color: AppTheme.accentColor,
                    onTap: () => _startDrawing(DrawMode.polygon),
                  ),
                  _buildToolButton(
                    icon: Icons.navigation,
                    label: 'stakeout'.tr(),
                    color: Colors.deepPurple,
                    onTap: _openStakeout,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _drawMode == DrawMode.none
          ? FloatingActionButton(
              mini: true,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: color,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
