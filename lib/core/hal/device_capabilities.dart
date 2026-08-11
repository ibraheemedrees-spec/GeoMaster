import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Detects what the current Android/iOS controller actually supports.
class DeviceCapabilities {
  final bool hasLocation;
  final bool hasBluetooth;
  final bool hasBle;
  final bool hasWifi;
  final bool hasNetwork;
  final String platform;
  final String? androidVersion;
  final String? deviceModel;

  const DeviceCapabilities({
    required this.hasLocation,
    required this.hasBluetooth,
    required this.hasBle,
    required this.hasWifi,
    required this.hasNetwork,
    required this.platform,
    this.androidVersion,
    this.deviceModel,
  });

  static Future<DeviceCapabilities> detect() async {
    bool location = false;
    bool bluetooth = false;
    bool ble = false;

    try {
      location = await Geolocator.isLocationServiceEnabled();
    } catch (_) {}

    try {
      bluetooth = await FlutterBluePlus.isSupported;
      if (bluetooth) {
        final state = await FlutterBluePlus.adapterState.first
            .timeout(const Duration(seconds: 2), onTimeout: () => BluetoothAdapterState.unknown);
        ble = state != BluetoothAdapterState.unavailable;
      }
    } catch (_) {}

    String platform = 'unknown';
    String? androidVersion;
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        platform = 'android';
        androidVersion = Platform.operatingSystemVersion;
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else {
        platform = Platform.operatingSystem;
      }
    }

    return DeviceCapabilities(
      hasLocation: location,
      hasBluetooth: bluetooth,
      hasBle: ble,
      hasWifi: true, // cannot reliably detect without extra plugins
      hasNetwork: true,
      platform: platform,
      androidVersion: androidVersion,
      deviceModel: null,
    );
  }
}
