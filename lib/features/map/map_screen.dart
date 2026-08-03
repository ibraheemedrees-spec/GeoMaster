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
import '../reports/report_screen.dart';
import '../layers/layers_screen.dart';
import '../edit/edit_point_screen.dart';
import '../stakeout/stakeout_screen.dart';

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
  bool _mapError = false;
  DrawMode _drawMode = DrawMode.none;
  List<LatLng> _currentDrawingPoints = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    // Don't block UI - open immediately
    _isLoadingLocation = false;
    try {
      _loadMapObjects();
    } catch (_) {}
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 8), onTimeout: () => LocationPermission.denied);
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      try {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 17),
        );
      } catch (_) {}
    } catch (_) {
      // ignore - app continues without GPS
    }
  }

  void _loadMapObjects() {
    try {
      final markers = <Marker>{};
      for (final point in widget.project.points) {
        markers.add(
          Marker(
            markerId: MarkerId(point.id),
            position: LatLng(point.latitude, point.longitude),
            infoWindow: InfoWindow(
              title: point.name,
              snippet: '±${point.accuracy.toStringAsFixed(1)} m',
            ),
            onTap: () async {
              try {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPointScreen(project: widget.project, point: point),
                  ),
                );
                if (result == true && mounted) _loadMapObjects();
              } catch (_) {}
            },
          ),
        );
      }

      final polylines = <Polyline>{};
      for (final line in widget.project.lines) {
        if (line.points.length >= 2) {
          polylines.add(Polyline(
            polylineId: PolylineId(line.id),
            points: line.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: AppTheme.secondaryColor,
            width: 4,
          ));
        }
      }

      final polygons = <Polygon>{};
      for (final poly in widget.project.polygons) {
        if (poly.points.length >= 3) {
          polygons.add(Polygon(
            polygonId: PolygonId(poly.id),
            points: poly.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            fillColor: AppTheme.accentColor.withOpacity(0.3),
            strokeColor: AppTheme.accentColor,
            strokeWidth: 3,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
          _polylines = polylines;
          _polygons = polygons;
        });
      }
    } catch (_) {}
  }

  Future<void> _openCollectPoint() async {
    Position pos = _currentPosition ??
        Position(
          latitude: 30.0444,
          longitude: 31.2357,
          timestamp: DateTime.now(),
          accuracy: 50,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

    try {
      if (_currentPosition == null) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        if (mounted) setState(() => _currentPosition = pos);
      }
    } catch (_) {}

    if (!mounted) return;
    try {
      final result = await Navigator.push<PointModel>(
        context,
        MaterialPageRoute(
          builder: (_) => CollectPointScreen(
            project: widget.project,
            currentPosition: pos,
            accuracyMode: _accuracyMode,
          ),
        ),
      );
      if (result != null && mounted) {
        widget.project.points.add(result);
        widget.project.updatedAt = DateTime.now();
        await widget.project.save();
        _loadMapObjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _startDrawing(DrawMode mode) {
    setState(() {
      _drawMode = mode;
      _currentDrawingPoints = [];
    });
  }

  void _onMapTap(LatLng position) {
    if (_drawMode == DrawMode.none) return;
    setState(() {
      _currentDrawingPoints.add(position);
      _markers = {
        ..._markers,
        Marker(
          markerId: MarkerId('temp_${_currentDrawingPoints.length}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _drawMode == DrawMode.line ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
        ),
      };
      if (_drawMode == DrawMode.line && _currentDrawingPoints.length >= 2) {
        _polylines = {
          ..._polylines.where((p) => p.polylineId.value != 'temp_line'),
          Polyline(
            polylineId: const PolylineId('temp_line'),
            points: List.from(_currentDrawingPoints),
            color: AppTheme.secondaryColor.withOpacity(0.7),
            width: 3,
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

  double _dist(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _finishDrawing() {
    try {
      if (_drawMode == DrawMode.line) {
        if (_currentDrawingPoints.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('need_at_least_2_points'.tr())));
          return;
        }
        final points = _currentDrawingPoints
            .map((ll) => PointModel(
                  name: 'L${widget.project.lines.length + 1}',
                  latitude: ll.latitude,
                  longitude: ll.longitude,
                  altitude: _currentPosition?.altitude ?? 0,
                  accuracy: _currentPosition?.accuracy ?? 0,
                  collectionMode: _accuracyMode,
                ))
            .toList();
        double length = 0;
        for (int i = 0; i < points.length - 1; i++) {
          length += _dist(points[i].latitude, points[i].longitude, points[i + 1].latitude, points[i + 1].longitude);
        }
        widget.project.lines.add(LineModel(name: 'Line ${widget.project.lines.length + 1}', points: points, length: length));
        widget.project.updatedAt = DateTime.now();
        widget.project.save();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'line_saved'.tr()} • ${length.toStringAsFixed(1)} m')));
      } else if (_drawMode == DrawMode.polygon) {
        if (_currentDrawingPoints.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('need_at_least_3_points'.tr())));
          return;
        }
        final points = _currentDrawingPoints
            .map((ll) => PointModel(
                  name: 'Ply',
                  latitude: ll.latitude,
                  longitude: ll.longitude,
                  altitude: _currentPosition?.altitude ?? 0,
                  accuracy: _currentPosition?.accuracy ?? 0,
                  collectionMode: _accuracyMode,
                ))
            .toList();
        double area = 0;
        for (int i = 0; i < points.length; i++) {
          final j = (i + 1) % points.length;
          area += points[i].longitude * points[j].latitude;
          area -= points[j].longitude * points[i].latitude;
        }
        area = (area.abs() / 2.0) * 111320.0 * 111320.0;
        double perimeter = 0;
        for (int i = 0; i < points.length; i++) {
          final j = (i + 1) % points.length;
          perimeter += _dist(points[i].latitude, points[i].longitude, points[j].latitude, points[j].longitude);
        }
        widget.project.polygons.add(PolygonModel(
          name: 'Polygon ${widget.project.polygons.length + 1}',
          points: points,
          area: area,
          perimeter: perimeter,
        ));
        widget.project.updatedAt = DateTime.now();
        widget.project.save();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'polygon_saved'.tr()} • ${area.toStringAsFixed(0)} m²')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() {
      _drawMode = DrawMode.none;
      _currentDrawingPoints = [];
    });
    _loadMapObjects();
  }

  void _cancelDrawing() {
    setState(() {
      _drawMode = DrawMode.none;
      _currentDrawingPoints = [];
    });
    _loadMapObjects();
  }

  void _openStakeout() {
    if (widget.project.points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_point_stakeout'.tr())));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('select_point_stakeout'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...widget.project.points.map((point) => ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(point.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StakeoutScreen(project: widget.project, targetPoint: point),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(30.0444, 31.2357);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (_drawMode != DrawMode.none) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _finishDrawing),
            IconButton(icon: const Icon(Icons.close), onPressed: _cancelDrawing),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.assessment),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(project: widget.project))),
            ),
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LayersScreen(project: widget.project))),
            ),
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(project: widget.project))),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          if (_drawMode == DrawMode.none)
            Material(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed, size: 18, color: AppTheme.primaryColor),
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
                          onChanged: (v) {
                            if (v != null) setState(() => _accuracyMode = v);
                          },
                        ),
                      ),
                    ),
                    if (_currentPosition != null)
                      Text(
                        '±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

          // Map or fallback list
          Expanded(
            child: _mapError
                ? _buildFallbackList()
                : Builder(
                    builder: (context) {
                      try {
                        return GoogleMap(
                          initialCameraPosition: CameraPosition(target: initial, zoom: 15),
                          onMapCreated: (c) {
                            _mapController = c;
                          },
                          onTap: _onMapTap,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          markers: _markers,
                          polylines: _polylines,
                          polygons: _polygons,
                          mapType: MapType.normal,
                          zoomControlsEnabled: false,
                          liteModeEnabled: false,
                        );
                      } catch (e) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _mapError = true);
                        });
                        return _buildFallbackList();
                      }
                    },
                  ),
          ),

          // Tools
          if (_drawMode == DrawMode.none)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _tool(Icons.add_location_alt, 'collect_point'.tr(), AppTheme.primaryColor, _openCollectPoint),
                    _tool(Icons.timeline, 'draw_line'.tr(), AppTheme.secondaryColor, () => _startDrawing(DrawMode.line)),
                    _tool(Icons.pentagon, 'draw_polygon'.tr(), AppTheme.accentColor, () => _startDrawing(DrawMode.polygon)),
                    _tool(Icons.navigation, 'stakeout'.tr(), Colors.deepPurple, _openStakeout),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _drawMode == DrawMode.line
                            ? '${'drawing_line'.tr()} (${_currentDrawingPoints.length})'
                            : '${'drawing_polygon'.tr()} (${_currentDrawingPoints.length})',
                      ),
                    ),
                    ElevatedButton(onPressed: _finishDrawing, child: Text('finish'.tr())),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _cancelDrawing, child: Text('cancel'.tr())),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Text(
          'الخريطة غير متاحة (محتاج Google Maps API Key).\nتقدر تشتغل بالقائمة عادي.',
          textAlign: TextAlign.center,
        ),
        const Divider(),
        Text('${'points'.tr()}: ${widget.project.points.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ...widget.project.points.map((p) => ListTile(
              title: Text(p.name),
              subtitle: Text('${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}'),
              trailing: Text('±${p.accuracy.toStringAsFixed(0)}m'),
            )),
        const Divider(),
        Text('${'lines'.tr()}: ${widget.project.lines.length}'),
        Text('${'polygons'.tr()}: ${widget.project.polygons.length}'),
      ],
    );
  }

  Widget _tool(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: label,
          backgroundColor: color,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
