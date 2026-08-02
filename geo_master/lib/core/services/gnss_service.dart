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
  final String quality; // single, dgps, rtk_float, rtk_fixed
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
  BluetoothCharacteristic? _nmeaCharacteristic;
  StreamSubscription? _notifySubscription;

  final _positionController = StreamController<GnssPosition>.broadcast();
  Stream<GnssPosition> get positionStream => _positionController.stream;

  bool get isConnected => _connectedDevice != null;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  Stream<List<ScanResult>> scanDevices({Duration timeout = const Duration(seconds: 10)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.indicate) {
            _nmeaCharacteristic = char;
            await char.setNotifyValue(true);

            _notifySubscription = char.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                final nmea = utf8.decode(value, allowMalformed: true);
                _parseNmea(nmea);
              }
            });
            break;
          }
        }
        if (_nmeaCharacteristic != null) break;
      }

      return true;
    } catch (e) {
      _connectedDevice = null;
      return false;
    }
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    _nmeaCharacteristic = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
  }

  void _parseNmea(String data) {
    final lines = data.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('\$GPGGA') || line.startsWith('\$GNGGA') || line.startsWith('\$GLGGA')) {
        _parseGGA(line);
      }
    }
  }

  void _parseGGA(String sentence) {
    try {
      final parts = sentence.split(',');
      if (parts.length < 10) return;

      final latRaw = parts[2];
      final latDir = parts[3];
      if (latRaw.isEmpty) return;

      double lat = _nmeaToDecimal(latRaw);
      if (latDir == 'S') lat = -lat;

      final lonRaw = parts[4];
      final lonDir = parts[5];
      double lon = _nmeaToDecimal(lonRaw);
      if (lonDir == 'W') lon = -lon;

      final qualityCode = int.tryParse(parts[6]) ?? 0;
      String quality = 'single';
      switch (qualityCode) {
        case 1: quality = 'single'; break;
        case 2: quality = 'dgps'; break;
        case 4: quality = 'rtk_fixed'; break;
        case 5: quality = 'rtk_float'; break;
      }

      final sats = int.tryParse(parts[7]);
      final hdop = double.tryParse(parts[8]);
      final alt = double.tryParse(parts[9]) ?? 0.0;

      double accuracy = 5.0;
      if (hdop != null) {
        accuracy = hdop * 2.5;
        if (quality == 'rtk_fixed') accuracy = 0.02;
        if (quality == 'rtk_float') accuracy = 0.2;
        if (quality == 'dgps') accuracy = 0.5;
      }

      final position = GnssPosition(
        latitude: lat,
        longitude: lon,
        altitude: alt,
        accuracy: accuracy,
        hdop: hdop,
        satellites: sats,
        quality: quality,
      );

      _positionController.add(position);
    } catch (_) {}
  }

  double _nmeaToDecimal(String nmea) {
    if (nmea.isEmpty) return 0;
    final value = double.tryParse(nmea) ?? 0;
    final degrees = value ~/ 100;
    final minutes = value % 100;
    return degrees + (minutes / 60.0);
  }

  Future<GnssPosition?> getPhonePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return GnssPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        accuracy: pos.accuracy,
        quality: 'single',
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
