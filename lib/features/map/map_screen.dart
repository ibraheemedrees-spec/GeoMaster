import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../data/models/line_model.dart';
import '../../data/models/polygon_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/gnss_service.dart';
import '../../core/survey/base_session.dart';
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
  final GnssService _gnss = GnssService();

  Position? _currentPosition;
  StreamSubscription<Position>? _gpsSub;
  StreamSubscription? _gnssSub;

  String _accuracyMode = 'single';
  DrawMode _drawMode = DrawMode.none;
  List<LatLng> _drawPoints = [];

  bool _followMe = true;
  bool _liveMarking = false; // continuous auto-mark while moving
  DateTime? _lastAutoMark;
  int _pointCounter = 0;

  @override
  void initState() {
    super.initState();
    _pointCounter = widget.project.points.length;
    _startLiveGps();
  }

  Future<void> _startLiveGps() async {
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

      // Prefer external GNSS stream if connected
      if (_gnss.isConnected) {
        _gnssSub = _gnss.positionStream.listen((g) {
          final pos = Position(
            latitude: g.latitude,
            longitude: g.longitude,
            timestamp: g.timestamp,
            accuracy: g.accuracy,
            altitude: g.altitude,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _onNewPosition(pos, fromGnss: true);
        });
      }

      // Always also listen to phone GPS as fallback / parallel
      _gpsSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1, // update every 1 meter
        ),
      ).listen((pos) {
        if (!_gnss.isConnected) {
          _onNewPosition(pos);
        }
      });

      // First fix
      final first = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 6),
      );
      _onNewPosition(first);
    } catch (_) {}
  }

  void _onNewPosition(Position pos, {bool fromGnss = false}) {
    if (!mounted) return;
    setState(() => _currentPosition = pos);

    if (_followMe) {
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      } catch (_) {}
    }

    // Live continuous marking
    if (_liveMarking && _drawMode == DrawMode.none) {
      final now = DateTime.now();
      if (_lastAutoMark == null || now.difference(_lastAutoMark!).inSeconds >= 3) {
        _lastAutoMark = now;
        _savePointAt(pos, quiet: true);
      }
    }
  }

  /// توقيع نقطة فوري من الموقع الحالي
  Future<void> _markHereNow({bool openDetails = false}) async {
    Position? pos;

    // دائماً نحاول قراءة GPS حديثة
    try {
      pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {
      pos = _currentPosition;
    }

    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('waiting_gps'.tr())),
        );
      }
      return;
    }

    if (openDetails) {
      final result = await Navigator.push<PointModel>(
        context,
        MaterialPageRoute(
          builder: (_) => CollectPointScreen(
            project: widget.project,
            currentPosition: pos!,
            accuracyMode: _gnss.isConnected ? 'external_gnss' : _accuracyMode,
          ),
        ),
      );
      if (result != null && mounted) {
        widget.project.points.add(result);
        widget.project.updatedAt = DateTime.now();
        await widget.project.save();
        setState(() => _pointCounter = widget.project.points.length);
      }
      return;
    }

    await _savePointAt(pos!);
  }

  Future<void> _savePointAt(Position pos, {bool quiet = false}) async {
    _pointCounter++;
    final mode = _gnss.isConnected ? 'external_gnss' : _accuracyMode;
    final point = PointModel(
      name: 'P$_pointCounter',
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      accuracy: pos.accuracy,
      description: quiet ? 'auto' : 'live',
      collectionMode: mode,
    );

    widget.project.points.add(point);
    widget.project.updatedAt = DateTime.now();
    await widget.project.save();

    if (mounted) {
      setState(() {});
      if (!quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${point.name}: ${pos.latitude.toStringAsFixed(7)}, ${pos.longitude.toStringAsFixed(7)}  ±${pos.accuracy.toStringAsFixed(1)}m',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  LatLng get _center {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    if (widget.project.points.isNotEmpty) {
      final p = widget.project.points.last;
      return LatLng(p.latitude, p.longitude);
    }
    return const LatLng(30.0444, 31.2357);
  }


  /// أثناء الرسم: أضف رأس من موقع GPS الحالي (نفس زر التوقيع)
  Future<void> _addDrawVertexFromGps() async {
    if (_drawMode == DrawMode.none) return;

    Position? pos = _currentPosition;
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 8),
        );
        if (mounted) setState(() => _currentPosition = pos);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('waiting_gps'.tr())),
          );
        }
        return;
      }
    }

    setState(() {
      _drawPoints.add(LatLng(pos!.latitude, pos.longitude));
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ نقطة ${_drawPoints.length}: ${pos.latitude.toStringAsFixed(7)}, ${pos.longitude.toStringAsFixed(7)} ±${pos.accuracy.toStringAsFixed(1)}m',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade700,
      ),
    );
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
                  subtitle: Text('±${p.accuracy.toStringAsFixed(1)} m'),
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
  void dispose() {
    _gpsSub?.cancel();
    _gnssSub?.cancel();
    super.dispose();
  }


  Widget _baseRoverCoordRow({
    required String label,
    required Color color,
    double? lat,
    double? lon,
    double? elev,
    String? extra,
  }) {
    final has = lat != null && lon != null;
    final coord = has
        ? '${lat!.toStringAsFixed(8)}, ${lon!.toStringAsFixed(8)}'
        : '--';
    final elevStr = elev != null ? '  H ${elev.toStringAsFixed(3)} m' : '';
    final extraStr = (extra != null && extra.isNotEmpty) ? '  $extra' : '';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$coord$elevStr$extraStr',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: has ? Colors.black87 : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditPointScreen(project: widget.project, point: p)),
                );
                if (r == true && mounted) setState(() {});
              },
              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
            ),
          )),
      ..._drawPoints.map((ll) => Marker(
            point: ll,
            width: 28,
            height: 28,
            child: Icon(Icons.circle, size: 14, color: _drawMode == DrawMode.line ? Colors.green : Colors.orange),
          )),
      // Live GPS marker
      if (_currentPosition != null)
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: _gnss.isConnected ? Colors.green : Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
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
        Polygon(
          points: List.from(_drawPoints),
          color: Colors.orange.withOpacity(0.2),
          borderColor: Colors.orange,
          borderStrokeWidth: 2,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (_drawMode != DrawMode.none) ...[
            IconButton(icon: const Icon(Icons.check), onPressed: _finishDraw),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _drawMode = DrawMode.none;
                _drawPoints = [];
              }),
            ),
          ] else ...[
            // Live continuous marking toggle
            IconButton(
              icon: Icon(_liveMarking ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
                  color: _liveMarking ? Colors.redAccent : null),
              tooltip: 'Live track',
              onPressed: () {
                setState(() => _liveMarking = !_liveMarking);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_liveMarking ? 'Live marking ON (every 3s)' : 'Live marking OFF'),
                  duration: const Duration(seconds: 1),
                ));
              },
            ),
            IconButton(
              icon: Icon(_followMe ? Icons.gps_fixed : Icons.gps_not_fixed),
              tooltip: 'Follow me',
              onPressed: () => setState(() => _followMe = !_followMe),
            ),
            IconButton(icon: const Icon(Icons.assessment), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(project: widget.project)))),
            IconButton(icon: const Icon(Icons.file_upload), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(project: widget.project)))),
          ],
        ],
      ),
      body: Column(
        children: [
          // Live coords bar
          Material(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _gnss.isConnected ? Icons.bluetooth_connected : Icons.gps_fixed,
                    color: _gnss.isConnected ? Colors.greenAccent : Colors.lightBlueAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _currentPosition == null
                        ? Text('waiting_gps'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12))
                        : Text(
                            '${_currentPosition!.latitude.toStringAsFixed(7)}, ${_currentPosition!.longitude.toStringAsFixed(7)}  ±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                          ),
                  ),
                  Text('${widget.project.points.length} pts', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ),

          // Base & Rover coordinates (replaces phone mode list)
          if (_drawMode == DrawMode.none)
            Material(
              elevation: 1,
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _baseRoverCoordRow(
                      label: 'BASE',
                      color: Colors.indigo,
                      lat: BaseSession.instance.latitude,
                      lon: BaseSession.instance.longitude,
                      elev: BaseSession.instance.elevation,
                      extra: BaseSession.instance.pointName,
                    ),
                    const SizedBox(height: 4),
                    _baseRoverCoordRow(
                      label: 'ROVER',
                      color: Colors.teal,
                      lat: _currentPosition?.latitude,
                      lon: _currentPosition?.longitude,
                      elev: _currentPosition?.altitude,
                      extra: _currentPosition == null
                          ? null
                          : '±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 17,
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

          // Big LIVE MARK button + tools
          if (_drawMode == DrawMode.none)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    // Primary: mark here NOW
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _markHereNow(openDetails: false),
                        onLongPress: () => _markHereNow(openDetails: true),
                        icon: const Icon(Icons.add_location_alt, size: 28),
                        label: const Text(
                          'توقيع نقطة الآن (من GPS)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('اضغط للتوقيع الفوري • اضغط مطولًا مع التفاصيل', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _btn(Icons.edit_location_alt, 'تفاصيل', AppTheme.primaryColor, () => _markHereNow(openDetails: true)),
                        _btn(Icons.timeline, 'draw_line'.tr(), AppTheme.secondaryColor, () => setState(() { _drawMode = DrawMode.line; _drawPoints = []; })),
                        _btn(Icons.pentagon, 'draw_polygon'.tr(), AppTheme.accentColor, () => setState(() { _drawMode = DrawMode.polygon; _drawPoints = []; })),
                        _btn(Icons.navigation, 'stakeout'.tr(), Colors.deepPurple, _openStakeout),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // نفس زر التوقيع الأخضر - يضيف رأس من GPS
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _addDrawVertexFromGps,
                        icon: const Icon(Icons.add_location_alt, size: 28),
                        label: Text(
                          _drawMode == DrawMode.line
                              ? 'توقيع نقطة خط من GPS (${_drawPoints.length})'
                              : 'توقيع نقطة مساحة من GPS (${_drawPoints.length})',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _drawMode == DrawMode.line
                          ? 'قف عند الرأس واضغط توقيع — ثم إنهاء لحفظ الخط'
                          : 'قف عند الرأس واضغط توقيع — 3 نقاط على الأقل ثم إنهاء',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _drawMode == DrawMode.line
                                ? '${'drawing_line'.tr()} (${_drawPoints.length})'
                                : '${'drawing_polygon'.tr()} (${_drawPoints.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _finishDraw,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text('finish'.tr()),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() { _drawMode = DrawMode.none; _drawPoints = []; }),
                          child: Text('cancel'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: label,
          backgroundColor: color,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
