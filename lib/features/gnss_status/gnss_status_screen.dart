import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/gnss/gnss_engine.dart';
import '../../core/gnss/gnss_fix.dart';
import '../../core/gnss/quality_control.dart';
import '../../core/survey/survey_config.dart';

class GnssStatusScreen extends StatefulWidget {
  const GnssStatusScreen({super.key});

  @override
  State<GnssStatusScreen> createState() => _GnssStatusScreenState();
}

class _GnssStatusScreenState extends State<GnssStatusScreen> {
  final _engine = GnssEngine();
  StreamSubscription? _sub;
  GnssFix _fix = GnssFix.empty();

  @override
  void initState() {
    super.initState();
    _fix = _engine.lastFix;
    _sub = _engine.fixStream.listen((f) {
      if (mounted) setState(() => _fix = f);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Color _rtkColor(String s) {
    switch (s) {
      case 'FIXED':
        return Colors.green;
      case 'FLOAT':
        return Colors.orange;
      case 'DGPS':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final limits = SurveyConfigStore.activeConfig()?.quality ?? QualityLimits();
    final qc = QualityControl.evaluate(_fix, limits);

    return Scaffold(
      appBar: AppBar(title: const Text('GNSS Status')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _fix.rtkStatus,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _rtkColor(_fix.rtkStatus)),
                  ),
                  Text('Source: ${_fix.source}', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: qc.status == QcStatus.acceptable
                          ? Colors.green
                          : qc.status == QcStatus.warning
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(qc.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _row('Latitude', _fix.latStr),
          _row('Longitude', _fix.lonStr),
          _row('Ellipsoidal H', '${_fix.fmt(_fix.ellipsoidalHeight, 3)} m'),
          _row('Orthometric H', _fix.orthometricHeight == null ? '--' : '${_fix.fmt(_fix.orthometricHeight, 3)} m'),
          _row('Geoid N', _fix.geoidSeparation == null ? 'unavailable' : '${_fix.fmt(_fix.geoidSeparation, 3)} m'),
          const Divider(),
          _row('H Accuracy', '${_fix.fmt(_fix.horizontalAccuracy, 3)} m'),
          _row('V Accuracy', '${_fix.fmt(_fix.verticalAccuracy, 3)} m'),
          _row('Satellites', '${_fix.satellitesUsed ?? '--'} / ${_fix.satellitesVisible ?? '--'}'),
          _row('PDOP', _fix.fmt(_fix.pdop, 1)),
          _row('HDOP', _fix.fmt(_fix.hdop, 1)),
          _row('VDOP', _fix.fmt(_fix.vdop, 1)),
          _row('Corr Age', _fix.correctionAgeSec == null ? '--' : '${_fix.fmt(_fix.correctionAgeSec, 1)} s'),
          _row('Heading', _fix.heading == null ? '--' : '${_fix.fmt(_fix.heading, 1)}°'),
          _row('Speed', _fix.speedMps == null ? '--' : '${_fix.fmt(_fix.speedMps, 2)} m/s'),
          _row('GNSS Time', _fix.gnssTime?.toIso8601String() ?? '--'),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: TextStyle(color: Colors.grey.shade700))),
          Text(v, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
