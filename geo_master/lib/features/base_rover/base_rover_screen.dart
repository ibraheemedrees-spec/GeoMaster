import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';

enum DeviceRole { none, base, rover }

class BaseRoverScreen extends StatefulWidget {
  const BaseRoverScreen({super.key});

  @override
  State<BaseRoverScreen> createState() => _BaseRoverScreenState();
}

class _BaseRoverScreenState extends State<BaseRoverScreen> {
  DeviceRole _role = DeviceRole.none;
  Position? _basePosition;
  Position? _currentPosition;
  StreamSubscription<Position>? _posSub;

  double? _deltaNorth;
  double? _deltaEast;
  double? _baseline;

  void _setRole(DeviceRole role) {
    setState(() {
      _role = role;
      _deltaNorth = null;
      _deltaEast = null;
      _baseline = null;
    });
    _posSub?.cancel();

    if (role != DeviceRole.none) {
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
      ).listen((pos) {
        setState(() => _currentPosition = pos);
        if (role == DeviceRole.base) {
          if (_basePosition == null) {
            _basePosition = pos;
          } else {
            _basePosition = Position(
              latitude: (_basePosition!.latitude * 0.7 + pos.latitude * 0.3),
              longitude: (_basePosition!.longitude * 0.7 + pos.longitude * 0.3),
              timestamp: pos.timestamp,
              accuracy: pos.accuracy,
              altitude: (_basePosition!.altitude * 0.7 + pos.altitude * 0.3),
              altitudeAccuracy: pos.altitudeAccuracy,
              heading: pos.heading,
              headingAccuracy: pos.headingAccuracy,
              speed: pos.speed,
              speedAccuracy: pos.speedAccuracy,
            );
          }
        } else if (role == DeviceRole.rover && _basePosition != null) {
          _computeRelative(pos);
        }
      });
    }
  }

  void _computeRelative(Position rover) {
    final dLat = (rover.latitude - _basePosition!.latitude) * 111320.0;
    final cosLat = math.cos(rover.latitude * math.pi / 180);
    final dLon = (rover.longitude - _basePosition!.longitude) * 111320.0 * cosLat;
    final bl = math.sqrt(dLat * dLat + dLon * dLon);
    setState(() {
      _deltaNorth = dLat;
      _deltaEast = dLon;
      _baseline = bl;
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('base_rover_mode'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('select_role'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _role == DeviceRole.base ? AppTheme.primaryColor : Colors.grey.shade300,
                            foregroundColor: _role == DeviceRole.base ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => _setRole(DeviceRole.base),
                          child: Text('role_base'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _role == DeviceRole.rover ? AppTheme.secondaryColor : Colors.grey.shade300,
                            foregroundColor: _role == DeviceRole.rover ? Colors.white : Colors.black87,
                          ),
                          onPressed: () => _setRole(DeviceRole.rover),
                          child: Text('role_rover'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_role == DeviceRole.base) ...[
            _infoCard('role_base'.tr(), [
              if (_basePosition != null) ...[
                'Lat: ${_basePosition!.latitude.toStringAsFixed(8)}',
                'Lng: ${_basePosition!.longitude.toStringAsFixed(8)}',
                'Alt: ${_basePosition!.altitude.toStringAsFixed(2)} m',
                'Acc: ±${_basePosition!.accuracy.toStringAsFixed(1)} m',
              ] else
                'waiting_gps'.tr(),
            ], Colors.blue),
            const SizedBox(height: 8),
            Text('base_note'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
          if (_role == DeviceRole.rover) ...[
            if (_basePosition == null)
              Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text('set_base_first'.tr()),
                ),
              )
            else ...[
              _infoCard('Base', [
                'Lat: ${_basePosition!.latitude.toStringAsFixed(8)}',
                'Lng: ${_basePosition!.longitude.toStringAsFixed(8)}',
              ], Colors.blue),
              const SizedBox(height: 8),
              _infoCard('Rover', [
                if (_currentPosition != null) ...[
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(8)}',
                  'Lng: ${_currentPosition!.longitude.toStringAsFixed(8)}',
                  'Acc: ±${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                ] else
                  'waiting_gps'.tr(),
              ], Colors.green),
              if (_deltaNorth != null) ...[
                const SizedBox(height: 8),
                _infoCard('Relative', [
                  'ΔN: ${_deltaNorth!.toStringAsFixed(2)} m',
                  'ΔE: ${_deltaEast!.toStringAsFixed(2)} m',
                  'Baseline: ${_baseline!.toStringAsFixed(2)} m',
                ], Colors.purple),
              ],
            ],
          ],
          const SizedBox(height: 24),
          Text(
            'base_rover_limitation'.tr(),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<String> lines, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            ...lines.map((l) => Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
