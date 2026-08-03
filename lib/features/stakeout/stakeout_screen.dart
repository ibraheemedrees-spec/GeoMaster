import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/gnss_service.dart';

class StakeoutScreen extends StatefulWidget {
  final ProjectModel project;
  final PointModel targetPoint;
  const StakeoutScreen({super.key, required this.project, required this.targetPoint});

  @override
  State<StakeoutScreen> createState() => _StakeoutScreenState();
}

class _StakeoutScreenState extends State<StakeoutScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _posSub;
  final GnssService _gnss = GnssService();
  StreamSubscription? _gnssSub;
  double _distance = 0;
  double _bearing = 0;
  String _direction = '';
  LatLng? _myPos;

  @override
  void initState() {
    super.initState();
    if (_gnss.isConnected) {
      _gnssSub = _gnss.positionStream.listen((p) => _update(p.latitude, p.longitude));
    }
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1),
    ).listen((pos) {
      if (!_gnss.isConnected) _update(pos.latitude, pos.longitude);
    });
  }

  void _update(double lat, double lng) {
    final dist = _calcDist(lat, lng, widget.targetPoint.latitude, widget.targetPoint.longitude);
    final bear = _calcBearing(lat, lng, widget.targetPoint.latitude, widget.targetPoint.longitude);
    setState(() {
      _distance = dist;
      _bearing = bear;
      _direction = _dir(bear);
      _myPos = LatLng(lat, lng);
    });
    try {
      _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
    } catch (_) {}
  }

  double _calcDist(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _calcBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2 * math.pi / 180);
    final x = math.cos(lat1 * math.pi / 180) * math.sin(lat2 * math.pi / 180) -
        math.sin(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  String _dir(double b) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((b + 22.5) % 360 / 45).floor()];
  }

  Color get _color {
    if (_distance < 0.5) return Colors.green;
    if (_distance < 2) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _gnssSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = LatLng(widget.targetPoint.latitude, widget.targetPoint.longitude);
    return Scaffold(
      appBar: AppBar(title: Text('${'stakeout'.tr()}: ${widget.targetPoint.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: Column(
              children: [
                Text(
                  _distance < 1000 ? '${_distance.toStringAsFixed(2)} m' : '${(_distance / 1000).toStringAsFixed(2)} km',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _color),
                ),
                Text('$_direction  •  ${_bearing.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 18)),
                if (_distance < 0.3)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
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
                  if (_myPos != null)
                    Marker(
                      point: _myPos!,
                      width: 20,
                      height: 20,
                      child: Container(decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
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
                    '${widget.targetPoint.name}\n${widget.targetPoint.latitude.toStringAsFixed(8)}, ${widget.targetPoint.longitude.toStringAsFixed(8)}',
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
}
