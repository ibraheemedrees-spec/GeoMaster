import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';
import '../../core/gnss/gnss_engine.dart';
import '../../core/gnss/gnss_fix.dart';
import '../../core/gnss/quality_control.dart';
import '../../core/survey/survey_config.dart';

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
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _engine = GnssEngine();
  StreamSubscription? _sub;
  GnssFix _fix = GnssFix.empty();
  bool _isAveraging = false;
  int _epochCount = 0;
  double _sumLat = 0, _sumLng = 0, _sumAlt = 0, _sumAcc = 0;

  SurveyConfig? get _cfg => SurveyConfigStore.activeConfig();

  @override
  void initState() {
    super.initState();
    _nameController.text = 'P${widget.project.points.length + 1}';
    _fix = _engine.lastFix;
    if (!_fix.hasPosition) {
      _fix = GnssFix(
        latitude: widget.currentPosition.latitude,
        longitude: widget.currentPosition.longitude,
        ellipsoidalHeight: widget.currentPosition.altitude,
        horizontalAccuracy: widget.currentPosition.accuracy,
        fixType: 'gps',
        rtkStatus: 'SINGLE',
        source: 'internal',
        timestamp: DateTime.now(),
      );
    }
    _sub = _engine.fixStream.listen((f) {
      if (!_isAveraging && mounted) setState(() => _fix = f);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  QualityResult get _qc {
    final limits = _cfg?.quality ?? QualityLimits(requireRtkFixed: false, maxHAccuracy: 50);
    return QualityControl.evaluate(_fix, limits);
  }

  Future<void> _runObservation() async {
    final method = _cfg?.observationMethod ?? 'instant';
    if (method == 'instant') return;

    setState(() {
      _isAveraging = true;
      _epochCount = 0;
      _sumLat = 0;
      _sumLng = 0;
      _sumAlt = 0;
      _sumAcc = 0;
    });

    final epochs = method == 'fixed_epochs'
        ? (_cfg?.minEpochs ?? 5)
        : (method == 'fixed_time' || method == 'average')
            ? ((_cfg?.observationSeconds ?? 5) * 2)
            : 5;

    for (int i = 0; i < epochs; i++) {
      if (!_isAveraging) break;
      final f = await _engine.getCurrentFix();
      if (f != null && f.hasPosition) {
        setState(() {
          _epochCount = i + 1;
          _sumLat += f.latitude!;
          _sumLng += f.longitude!;
          _sumAlt += f.ellipsoidalHeight ?? 0;
          _sumAcc += f.horizontalAccuracy ?? 0;
          _fix = GnssFix(
            latitude: _sumLat / _epochCount,
            longitude: _sumLng / _epochCount,
            ellipsoidalHeight: _sumAlt / _epochCount,
            horizontalAccuracy: _sumAcc / _epochCount,
            orthometricHeight: f.orthometricHeight,
            fixType: f.fixType,
            rtkStatus: f.rtkStatus,
            satellitesUsed: f.satellitesUsed,
            pdop: f.pdop,
            hdop: f.hdop,
            source: f.source,
            timestamp: DateTime.now(),
          );
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) setState(() => _isAveraging = false);
  }

  void _savePoint() {
    final qc = _qc;
    if (qc.status == QcStatus.notAcceptable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NOT ACCEPTABLE: ${qc.messages.join(', ')}'), backgroundColor: Colors.red),
      );
      return;
    }
    final ant = _cfg?.antenna.heightM ?? 0;
    final alt = (_fix.ellipsoidalHeight ?? 0) - ant;
    final point = PointModel(
      name: _nameController.text.trim().isEmpty
          ? 'P${widget.project.points.length + 1}'
          : _nameController.text.trim(),
      latitude: _fix.latitude!,
      longitude: _fix.longitude!,
      altitude: alt,
      accuracy: _fix.horizontalAccuracy ?? 0,
      description: [
        if (_codeController.text.trim().isNotEmpty) 'code=${_codeController.text.trim()}',
        _descController.text.trim(),
        'rtk=${_fix.rtkStatus}',
        'qc=${qc.label}',
      ].where((e) => e.isNotEmpty).join(' | '),
      collectionMode: widget.accuracyMode,
    );
    Navigator.pop(context, point);
  }

  @override
  Widget build(BuildContext context) {
    final qc = _qc;
    final qcColor = qc.status == QcStatus.acceptable
        ? Colors.green
        : qc.status == QcStatus.warning
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text('collect_point'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(qc.label, style: TextStyle(color: qcColor, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${_fix.latStr}, ${_fix.lonStr}', style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                    Text(
                      'H ±${_fix.fmt(_fix.horizontalAccuracy, 3)} m  •  ${_fix.rtkStatus}  •  sats ${_fix.satellitesUsed ?? "--"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    ...qc.messages.map((m) => Text(m, style: const TextStyle(color: Colors.white54, fontSize: 11))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'point_name'.tr(), border: const OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _descController, decoration: InputDecoration(labelText: 'description'.tr(), border: const OutlineInputBorder()), maxLines: 2),
            const SizedBox(height: 12),
            if (_isAveraging)
              Column(children: [
                LinearProgressIndicator(value: _epochCount / ((_cfg?.minEpochs ?? 5).clamp(1, 60))),
                Text('Epochs: $_epochCount'),
              ])
            else
              OutlinedButton.icon(
                onPressed: _runObservation,
                icon: const Icon(Icons.timelapse),
                label: Text('Observe (${_cfg?.observationMethod ?? "instant"})'),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: qcColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _fix.hasPosition && qc.status != QcStatus.notAcceptable ? _savePoint : null,
              icon: const Icon(Icons.check),
              label: Text(qc.status == QcStatus.notAcceptable ? 'REJECT' : 'ACCEPT POINT'),
            ),
          ],
        ),
      ),
    );
  }
}
