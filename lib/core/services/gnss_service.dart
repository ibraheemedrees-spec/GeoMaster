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

class GnssService {
  static final GnssService _instance = GnssService._internal();
  factory GnssService() => _instance;
  GnssService._internal();

  BluetoothDevice? _connectedDevice;
  StreamSubscription? _notifySubscription;
  final _positionController = StreamController<GnssPosition>.broadcast();

  Stream<GnssPosition> get positionStream => _positionController.stream;
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
  }

  void _parseNmea(String data) {
    for (final line in data.split('\n')) {
      final t = line.trim();
      if (t.startsWith('\$GPGGA') || t.startsWith('\$GNGGA') || t.startsWith('\$GLGGA')) {
        _parseGGA(t);
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
  }
}
