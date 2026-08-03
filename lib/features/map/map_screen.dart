import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

enum DrawMode { none, line, polygon }

class MapScreen extends StatefulWidget {
  final ProjectModel project;
  const MapScreen({super.key, required this.project});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  String _accuracyMode = 'single';
  DrawMode _drawMode = DrawMode.none;
  List<LatLng> _drawPoints = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 8), onTimeout: () => LocationPermission.denied);
      }
      if (perm != LocationPermission.whileInUse && perm != LocationPermission.always) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
      } catch (_) {}
    } catch (_) {}
  }

  LatLng get _center {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    if (widget.project.points.isNotEmpty) {
      final p = widget.project.points.first;
      return LatLng(p.latitude, p.longitude);
    }
    return const LatLng(30.0444, 31.2357);
  }

  Future<void> _collectPoint() async {
    Position pos = _currentPosition ??
        Position(
          latitude: _center.latitude,
          longitude: _center.longitude,
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
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}

    if (!mounted) return;
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
      setState(() {});
    }
  }

  void _onTap(TapPosition tapPos, LatLng latlng) {
    if (_drawMode == DrawMode.none) return;
    setState(() => _drawPoints.add(latlng));
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _finishDraw() {
    if (_drawMode == DrawMode.line) {
      if (_drawPoints.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('need_at_least_2_points'.tr())));
        return;
      }
      final pts = _drawPoints
          .map((ll) => PointModel(
                name: 'L',
                latitude: ll.latitude,
                longitude: ll.longitude,
                altitude: _currentPosition?.altitude ?? 0,
                accuracy: _currentPosition?.accuracy ?? 0,
                collectionMode: _accuracyMode,
              ))
          .toList();
      double len = 0;
      for (int i = 0; i < pts.length - 1; i++) {
        len += _haversine(pts[i].latitude, pts[i].longitude, pts[i + 1].latitude, pts[i + 1].longitude);
      }
      widget.project.lines.add(LineModel(name: 'Line ${widget.project.lines.length + 1}', points: pts, length: len));
      widget.project.save();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'line_saved'.tr()} ${len.toStringAsFixed(1)} m')));
    } else if (_drawMode == DrawMode.polygon) {
      if (_drawPoints.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('need_at_least_3_points'.tr())));
        return;
      }
      final pts = _drawPoints
          .map((ll) => PointModel(
                name: 'P',
                latitude: ll.latitude,
                longitude: ll.longitude,
                altitude: _currentPosition?.altitude ?? 0,
                accuracy: _currentPosition?.accuracy ?? 0,
                collectionMode: _accuracyMode,
              ))
          .toList();
      double area = 0;
      for (int i = 0; i < pts.length; i++) {
        final j = (i + 1) % pts.length;
        area += pts[i].longitude * pts[j].latitude - pts[j].longitude * pts[i].latitude;
      }
      area = (area.abs() / 2) * 111320 * 111320;
      double peri = 0;
      for (int i = 0; i < pts.length; i++) {
        final j = (i + 1) % pts.length;
        peri += _haversine(pts[i].latitude, pts[i].longitude, pts[j].latitude, pts[j].longitude);
      }
      widget.project.polygons.add(PolygonModel(
        name: 'Polygon ${widget.project.polygons.length + 1}',
        points: pts,
        area: area,
        perimeter: peri,
      ));
      widget.project.save();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'polygon_saved'.tr()} ${area.toStringAsFixed(0)} m²')));
    }
    setState(() {
      _drawMode = DrawMode.none;
      _drawPoints = [];
    });
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
            ListTile(title: Text('select_point_stakeout'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
            ...widget.project.points.map((p) => ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(p.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StakeoutScreen(project: widget.project, targetPoint: p)));
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      ...widget.project.points.map((p) => Marker(
            point: LatLng(p.latitude, p.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () async {
                final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditPointScreen(project: widget.project, point: p)));
                if (r == true && mounted) setState(() {});
              },
              child: const Icon(Icons.location_on, color: Colors.blue, size: 36),
            ),
          )),
      ..._drawPoints.asMap().entries.map((e) => Marker(
            point: e.value,
            width: 30,
            height: 30,
            child: Icon(Icons.circle, color: _drawMode == DrawMode.line ? Colors.green : Colors.orange, size: 16),
          )),
      if (_currentPosition != null)
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          ),
        ),
    ];

    final polylines = <Polyline>[
      ...widget.project.lines.where((l) => l.points.length >= 2).map((l) => Polyline(
            points: l.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: AppTheme.secondaryColor,
            strokeWidth: 4,
          )),
      if (_drawMode == DrawMode.line && _drawPoints.length >= 2)
        Polyline(points: List.from(_drawPoints), color: Colors.green, strokeWidth: 3),
    ];

    final polygons = <Polygon>[
      ...widget.project.polygons.where((p) => p.points.length >= 3).map((p) => Polygon(
            points: p.points.map((pt) => LatLng(pt.latitude, pt.longitude)).toList(),
            color: AppTheme.accentColor.withOpacity(0.3),
            borderColor: AppTheme.accentColor,
            borderStrokeWidth: 3,
          )),
      if (_drawMode == DrawMode.polygon && _drawPoints.length >= 2)
        Polygon(points: List.from(_drawPoints), color: Colors.orange.withOpacity(0.2), borderColor: Colors.orange, borderStrokeWidth: 2),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (_drawMode != DrawMode.none) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _finishDraw),
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _drawMode = DrawMode.none; _drawPoints = []; })),
          ] else ...[
            IconButton(icon: const Icon(Icons.assessment), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(project: widget.project)))),
            IconButton(icon: const Icon(Icons.layers), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LayersScreen(project: widget.project)))),
            IconButton(icon: const Icon(Icons.file_upload), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(project: widget.project)))),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_drawMode == DrawMode.none)
            Material(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          onChanged: (v) => setState(() => _accuracyMode = v ?? 'single'),
                        ),
                      ),
                    ),
                    if (_currentPosition != null)
                      Text('±${_currentPosition!.accuracy.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 16,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.geomaster.app',
                ),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          if (_drawMode == DrawMode.none)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _btn(Icons.add_location_alt, 'collect_point'.tr(), AppTheme.primaryColor, _collectPoint),
                    _btn(Icons.timeline, 'draw_line'.tr(), AppTheme.secondaryColor, () => setState(() { _drawMode = DrawMode.line; _drawPoints = []; })),
                    _btn(Icons.pentagon, 'draw_polygon'.tr(), AppTheme.accentColor, () => setState(() { _drawMode = DrawMode.polygon; _drawPoints = []; })),
                    _btn(Icons.navigation, 'stakeout'.tr(), Colors.deepPurple, _openStakeout),
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
                    Expanded(child: Text('${_drawMode == DrawMode.line ? 'drawing_line'.tr() : 'drawing_polygon'.tr()} (${_drawPoints.length})')),
                    ElevatedButton(onPressed: _finishDraw, child: Text('finish'.tr())),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: () => setState(() { _drawMode = DrawMode.none; _drawPoints = []; }), child: Text('cancel'.tr())),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _drawMode == DrawMode.none
          ? FloatingActionButton.small(
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 17);
                } else {
                  _initLocation();
                }
              },
              child: const Icon(Icons.my_location),
            )
          : null,
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(heroTag: label, backgroundColor: color, onPressed: onTap, child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
