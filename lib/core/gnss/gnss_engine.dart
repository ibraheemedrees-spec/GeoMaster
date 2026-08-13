import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../services/gnss_service.dart';
import '../hal/connection_manager.dart';
import 'geoid_engine.dart';
import 'gnss_fix.dart';
import '../survey/rover_session.dart';

/// Central GNSS engine. Prefer this over calling Geolocator/GnssService in UI.
class GnssEngine {
  static final GnssEngine _instance = GnssEngine._();
  factory GnssEngine() => _instance;
  GnssEngine._();

  final GnssService _gnss = GnssService();
  final ConnectionManager _conn = ConnectionManager();
  final GeoidEngine _geoid = GeoidEngine();

  final _fixController = StreamController<GnssFix>.broadcast();
  StreamSubscription? _extSub;
  StreamSubscription<Position>? _phoneSub;
  GnssFix _last = GnssFix.empty();

  Stream<GnssFix> get fixStream => _fixController.stream;
  GnssFix get lastFix => _last;
  bool get externalConnected => _gnss.isConnected;

  void start() {
    _extSub?.cancel();
    _phoneSub?.cancel();

    _extSub = _gnss.positionStream.listen((p) {
      final rtk = _mapQuality(p.quality);
      final fix = GnssFix(
        latitude: p.latitude,
        longitude: p.longitude,
        ellipsoidalHeight: p.altitude,
        orthometricHeight: _geoid.orthometric(p.altitude),
        geoidSeparation: _geoid.separation,
        horizontalAccuracy: p.accuracy,
        verticalAccuracy: p.accuracy * 1.5,
        fixType: p.quality,
        rtkStatus: rtk,
        satellitesUsed: p.satellites,
        satellitesVisible: _gnss.currentSatellites.length,
        hdop: p.hdop,
        pdop: p.hdop != null ? p.hdop! * 1.2 : null,
        vdop: p.hdop != null ? p.hdop! * 1.5 : null,
        gnssTime: p.timestamp,
        source: 'bluetooth',
        timestamp: DateTime.now(),
      );
      _publish(fix);
      RoverSession.instance.applySolution(rtk);
      _conn.onRawData([0x24], isRtcm: false); // mark activity
      _conn.nmeaDetected = true;
      _conn.onGnssPositionValid(isRtk: rtk == 'FIXED' || rtk == 'FLOAT');
    });

    _phoneSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((pos) {
      if (_gnss.isConnected) return; // external has priority
      final fix = GnssFix(
        latitude: pos.latitude,
        longitude: pos.longitude,
        ellipsoidalHeight: pos.altitude,
        orthometricHeight: _geoid.orthometric(pos.altitude),
        geoidSeparation: _geoid.separation,
        horizontalAccuracy: pos.accuracy,
        verticalAccuracy: pos.altitudeAccuracy > 0 ? pos.altitudeAccuracy : null,
        fixType: 'gps',
        rtkStatus: 'SINGLE',
        heading: pos.heading >= 0 ? pos.heading : null,
        speedMps: pos.speed >= 0 ? pos.speed : null,
        gnssTime: pos.timestamp,
        source: 'internal',
        timestamp: DateTime.now(),
      );
      _publish(fix);
      _conn.onGnssPositionValid(isRtk: false);
    }, onError: (_) {});
  }

  void stop() {
    _extSub?.cancel();
    _phoneSub?.cancel();
  }

  void _publish(GnssFix fix) {
    _last = fix;
    if (!_fixController.isClosed) _fixController.add(fix);
  }

  String _mapQuality(String q) {
    switch (q) {
      case 'rtk_fixed':
        return 'FIXED';
      case 'rtk_float':
        return 'FLOAT';
      case 'dgps':
        return 'DGPS';
      case 'single':
        return 'SINGLE';
      default:
        return 'NONE';
    }
  }

  Future<GnssFix?> getCurrentFix() async {
    if (_last.hasPosition) return _last;
    try {
      if (_gnss.isConnected) {
        // wait briefly for stream
        return _fixController.stream
            .timeout(const Duration(seconds: 5))
            .first;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 8),
      );
      return GnssFix(
        latitude: pos.latitude,
        longitude: pos.longitude,
        ellipsoidalHeight: pos.altitude,
        orthometricHeight: _geoid.orthometric(pos.altitude),
        geoidSeparation: _geoid.separation,
        horizontalAccuracy: pos.accuracy,
        fixType: 'gps',
        rtkStatus: 'SINGLE',
        source: 'internal',
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stop();
    _fixController.close();
  }
}
