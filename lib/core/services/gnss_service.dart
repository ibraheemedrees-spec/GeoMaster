import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

class GnssPosition {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double? hdop;
  final int? satellites;
  final String quality;
  final DateTime timestamp;

  GnssPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    this.hdop,
    this.satellites,
    this.quality = 'single',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// بيانات قمر صناعي واحد
class SatelliteInfo {
  final String constellation; // GPS, GLONASS, Galileo, BeiDou, Other
  final int prn;
  final int elevation; // degrees
  final int azimuth; // degrees
  final int snr; // signal-to-noise ratio
  final bool usedInFix;

  SatelliteInfo({
    required this.constellation,
    required this.prn,
    required this.elevation,
    required this.azimuth,
    required this.snr,
    this.usedInFix = false,
  });
}

class GnssService {
  static final GnssService _instance = GnssService._internal();
  factory GnssService() => _instance;
  GnssService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription? _notifySubscription;
  final _positionController = StreamController<GnssPosition>.broadcast();
  final _satellitesController = StreamController<List<SatelliteInfo>>.broadcast();

  final Map<String, SatelliteInfo> _satsMap = {};

  Stream<GnssPosition> get positionStream => _positionController.stream;
  Stream<List<SatelliteInfo>> get satellitesStream => _satellitesController.stream;
  List<SatelliteInfo> get currentSatellites => _satsMap.values.toList();

  bool get isConnected => _connectedDevice != null;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  Stream<List<ScanResult>> scanDevices({Duration timeout = const Duration(seconds: 12)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));
      _connectedDevice = device;
      final services = await device.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _notifySubscription = char.lastValueStream.listen((value) {
              if (value.isEmpty) return;
              final nmea = utf8.decode(value, allowMalformed: true);
              _parseNmea(nmea);
            });
            return true;
          }
        }
      }
      return true;
    } catch (_) {
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _satsMap.clear();
    _satellitesController.add([]);
  }

  void _parseNmea(String data) {
    for (final line in data.split('\n')) {
      final t = line.trim();
      if (t.startsWith('\$GPGGA') || t.startsWith('\$GNGGA') || t.startsWith('\$GLGGA')) {
        _parseGGA(t);
      } else if (t.contains('GSV')) {
        _parseGSV(t);
      }
    }
  }

  void _parseGGA(String sentence) {
    try {
      final p = sentence.split(',');
      if (p.length < 10 || p[2].isEmpty) return;
      double lat = _nmeaToDec(p[2]);
      if (p[3] == 'S') lat = -lat;
      double lon = _nmeaToDec(p[4]);
      if (p[5] == 'W') lon = -lon;
      final q = int.tryParse(p[6]) ?? 0;
      String quality = 'single';
      if (q == 2) quality = 'dgps';
      if (q == 4) quality = 'rtk_fixed';
      if (q == 5) quality = 'rtk_float';
      final sats = int.tryParse(p[7]);
      final hdop = double.tryParse(p[8]);
      final alt = double.tryParse(p[9]) ?? 0;
      double acc = 5;
      if (hdop != null) acc = hdop * 2.5;
      if (quality == 'rtk_fixed') acc = 0.02;
      if (quality == 'rtk_float') acc = 0.2;
      if (quality == 'dgps') acc = 0.5;
      _positionController.add(GnssPosition(
        latitude: lat,
        longitude: lon,
        altitude: alt,
        accuracy: acc,
        hdop: hdop,
        satellites: sats,
        quality: quality,
      ));
    } catch (_) {}
  }

  /// $GPGSV,3,1,12,01,40,083,46,02,17,308,41,... 
  void _parseGSV(String sentence) {
    try {
      final p = sentence.split(',');
      if (p.length < 4) return;

      String constellation = 'Other';
      final talker = p[0];
      if (talker.contains('GP')) constellation = 'GPS';
      else if (talker.contains('GL')) constellation = 'GLONASS';
      else if (talker.contains('GA')) constellation = 'Galileo';
      else if (talker.contains('GB') || talker.contains('BD')) constellation = 'BeiDou';
      else if (talker.contains('GQ')) constellation = 'QZSS';
      else if (talker.contains('GN')) constellation = 'GNSS';

      // pairs of 4: prn, elev, az, snr starting at index 4
      for (int i = 4; i + 3 < p.length; i += 4) {
        final prn = int.tryParse(p[i]) ?? 0;
        if (prn == 0) continue;
        final elev = int.tryParse(p[i + 1]) ?? 0;
        final az = int.tryParse(p[i + 2]) ?? 0;
        // SNR may have *checksum
        var snrStr = p[i + 3].split('*').first;
        final snr = int.tryParse(snrStr) ?? 0;

        final key = '$constellation-$prn';
        _satsMap[key] = SatelliteInfo(
          constellation: constellation,
          prn: prn,
          elevation: elev,
          azimuth: az,
          snr: snr,
          usedInFix: snr > 0,
        );
      }
      _satellitesController.add(_satsMap.values.toList());
    } catch (_) {}
  }

  double _nmeaToDec(String nmea) {
    final v = double.tryParse(nmea) ?? 0;
    return (v ~/ 100) + (v % 100) / 60.0;
  }

  Future<GnssPosition?> getPhonePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      return GnssPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        accuracy: pos.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    disconnect();
    _positionController.close();
    _satellitesController.close();
  }
}
