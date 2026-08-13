import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/gnss/gnss_engine.dart';
import '../../core/gnss/gnss_fix.dart';
import '../../core/survey/survey_config.dart';

class StakeoutScreen extends StatefulWidget {
  final ProjectModel project;
  final PointModel targetPoint;
  const StakeoutScreen({super.key, required this.project, required this.targetPoint});

  @override
  State<StakeoutScreen> createState() => _StakeoutScreenState();
}

class _StakeoutScreenState extends State<StakeoutScreen> {
  final MapController _mapController = MapController();
  final GnssEngine _engine = GnssEngine();
  StreamSubscription? _sub;
  GnssFix _fix = GnssFix.empty();
  double _distance = 0;
  double _bearing = 0;
  double _dN = 0;
  double _dE = 0;
  double _dH = 0;

  double get _tolerance =>
      SurveyConfigStore.activeConfig()?.stakeoutToleranceM ?? 0.05;

  @override
  void initState() {
    super.initState();
    _fix = _engine.lastFix;
    _sub = _engine.fixStream.listen((f) {
      if (!f.hasPosition) return;
      _update(f.latitude!, f.longitude!, f.ellipsoidalHeight);
      if (mounted) setState(() => _fix = f);
    });
  }

  void _update(double lat, double lng, double? h) {
    final tLat = widget.targetPoint.latitude;
    final tLng = widget.targetPoint.longitude;
    _distance = _haversine(lat, lng, tLat, tLng);
    _bearing = _calcBearing(lat, lng, tLat, tLng);
    // Local EN approximation
    const mpd = 111320.0;
    _dN = (tLat - lat) * mpd;
    _dE = (tLng - lng) * mpd * math.cos(lat * math.pi / 180);
    final th = widget.targetPoint.altitude;
    _dH = h == null ? 0 : th - h;
    try {
      _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    } catch (_) {}
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

  double _calcBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2 * math.pi / 180);
    final x = math.cos(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) -
        math.sin(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Color get _color {
    if (_distance <= _tolerance) return Colors.green;
    if (_distance < _tolerance * 5) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = LatLng(widget.targetPoint.latitude, widget.targetPoint.longitude);
    final myPos = _fix.hasPosition ? LatLng(_fix.latitude!, _fix.longitude!) : null;

    return Scaffold(
      appBar: AppBar(title: Text('${'stakeout'.tr()}: ${widget.targetPoint.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                Text(
                  _distance < 1000 ? '${_distance.toStringAsFixed(3)} m' : '${(_distance / 1000).toStringAsFixed(3)} km',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _color),
                ),
                Text('Bearing ${_bearing.toStringAsFixed(2)}°', style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _delta('dN', _dN),
                    _delta('dE', _dE),
                    _delta('dH', _dH),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fix.rtkStatus}  H±${_fix.fmt(_fix.horizontalAccuracy, 3)} m  tol≤${_tolerance.toStringAsFixed(3)} m',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (_distance <= _tolerance)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: Text('arrived'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: target, initialZoom: 18),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.geomaster.app'),
                MarkerLayer(markers: [
                  Marker(point: target, width: 40, height: 40, child: const Icon(Icons.flag, color: Colors.red, size: 36)),
                  if (myPos != null)
                    Marker(
                      point: myPos,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.targetPoint.name}\n'
                    '${widget.targetPoint.latitude.toStringAsFixed(8)}, ${widget.targetPoint.longitude.toStringAsFixed(8)}\n'
                    'Elev: ${widget.targetPoint.altitude.toStringAsFixed(3)} m',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _delta(String label, double v) {
    final sign = v >= 0 ? '+' : '';
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text('$sign${v.toStringAsFixed(3)} m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}
