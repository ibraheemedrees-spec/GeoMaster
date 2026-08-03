import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  final GnssService _gnssService = GnssService();
  StreamSubscription? _gnssSub;
  double _distance = 0;
  double _bearing = 0;
  String _direction = '';

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    if (_gnssService.isConnected) {
      _gnssSub = _gnssService.positionStream.listen((pos) {
        _updateNavigation(pos.latitude, pos.longitude);
      });
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 1),
    ).listen((pos) {
      if (!_gnssService.isConnected) _updateNavigation(pos.latitude, pos.longitude);
    });
  }

  void _updateNavigation(double lat, double lng) {
    final dist = _calcDist(lat, lng, widget.targetPoint.latitude, widget.targetPoint.longitude);
    final bear = _calcBearing(lat, lng, widget.targetPoint.latitude, widget.targetPoint.longitude);
    setState(() {
      _distance = dist;
      _bearing = bear;
      _direction = _dir(bear);
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  double _calcDist(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _calcBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _rad(lon2 - lon1);
    final y = math.sin(dLon) * math.cos(_rad(lat2));
    final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) - math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  double _rad(double d) => d * math.pi / 180;
  String _dir(double b) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((b + 22.5) % 360 / 45).floor()];
  }

  Color get _distColor {
    if (_distance < 0.5) return Colors.green;
    if (_distance < 2) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _gnssSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _distColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.navigation, color: Colors.white70, size: 20),
                    const SizedBox(width: 6),
                    Text('$_direction  •  ${_bearing.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
                if (_distance < 0.3)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                      child: Text('arrived'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.targetPoint.latitude, widget.targetPoint.longitude),
                zoom: 18,
              ),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('target'),
                  position: LatLng(widget.targetPoint.latitude, widget.targetPoint.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(title: widget.targetPoint.name),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('zone'),
                  center: LatLng(widget.targetPoint.latitude, widget.targetPoint.longitude),
                  radius: 1.0,
                  fillColor: Colors.red.withOpacity(0.2),
                  strokeColor: Colors.red,
                  strokeWidth: 2,
                ),
              },
              mapType: MapType.hybrid,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.flag, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.targetPoint.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${widget.targetPoint.latitude.toStringAsFixed(8)}, ${widget.targetPoint.longitude.toStringAsFixed(8)}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
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
