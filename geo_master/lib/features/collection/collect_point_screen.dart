import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../core/theme/app_theme.dart';

class CollectPointScreen extends StatefulWidget {
  final ProjectModel project;
  final Position currentPosition;
  final String accuracyMode;

  const CollectPointScreen({
    super.key,
    required this.project,
    required this.currentPosition,
    required this.accuracyMode,
  });

  @override
  State<CollectPointScreen> createState() => _CollectPointScreenState();
}

class _CollectPointScreenState extends State<CollectPointScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Position _position;
  bool _isAveraging = false;
  int _averageCount = 0;
  double _sumLat = 0, _sumLng = 0, _sumAlt = 0, _sumAcc = 0;

  @override
  void initState() {
    super.initState();
    _position = widget.currentPosition;
    _nameController.text = 'P${widget.project.points.length + 1}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _startAveraging() async {
    setState(() {
      _isAveraging = true;
      _averageCount = 0;
      _sumLat = 0;
      _sumLng = 0;
      _sumAlt = 0;
      _sumAcc = 0;
    });

    // Average 10 readings
    for (int i = 0; i < 10; i++) {
      if (!_isAveraging) break;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _averageCount = i + 1;
        _sumLat += pos.latitude;
        _sumLng += pos.longitude;
        _sumAlt += pos.altitude;
        _sumAcc += pos.accuracy;
        _position = Position(
          latitude: _sumLat / _averageCount,
          longitude: _sumLng / _averageCount,
          timestamp: pos.timestamp,
          accuracy: _sumAcc / _averageCount,
          altitude: _sumAlt / _averageCount,
          altitudeAccuracy: pos.altitudeAccuracy,
          heading: pos.heading,
          headingAccuracy: pos.headingAccuracy,
          speed: pos.speed,
          speedAccuracy: pos.speedAccuracy,
        );
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => _isAveraging = false);
  }

  void _savePoint() {
    final point = PointModel(
      name: _nameController.text.trim().isEmpty
          ? 'P${widget.project.points.length + 1}'
          : _nameController.text.trim(),
      latitude: _position.latitude,
      longitude: _position.longitude,
      altitude: _position.altitude,
      accuracy: _position.accuracy,
      description: _descController.text.trim(),
      collectionMode: widget.accuracyMode,
    );

    Navigator.pop(context, point);
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'base_rover':
        return 'mode_base_rover'.tr();
      case 'external_gnss':
        return 'mode_external_gnss'.tr();
      default:
        return 'mode_single'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('collect_point'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accuracy Mode Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    _modeLabel(widget.accuracyMode),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Coordinates Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _coordRow('Latitude', _position.latitude.toStringAsFixed(8)),
                    const Divider(),
                    _coordRow('Longitude', _position.longitude.toStringAsFixed(8)),
                    const Divider(),
                    _coordRow('Altitude', '${_position.altitude.toStringAsFixed(2)} m'),
                    const Divider(),
                    _coordRow(
                      'Accuracy',
                      '± ${_position.accuracy.toStringAsFixed(2)} m',
                      valueColor: _position.accuracy < 5
                          ? Colors.green
                          : _position.accuracy < 15
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Average button
            OutlinedButton.icon(
              onPressed: _isAveraging ? null : _startAveraging,
              icon: _isAveraging
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.av_timer),
              label: Text(
                _isAveraging
                    ? '${'averaging'.tr()} ($_averageCount/10)'
                    : 'average_readings'.tr(),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'point_name'.tr(),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'description'.tr(),
                prefixIcon: const Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton.icon(
              onPressed: _isAveraging ? null : _savePoint,
              icon: const Icon(Icons.save),
              label: Text('save_point'.tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
