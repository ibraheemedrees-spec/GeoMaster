import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';
import '../../core/services/gnss_service.dart';
import '../../core/gnss/gnss_engine.dart';

class BaseRunningScreen extends StatefulWidget {
  const BaseRunningScreen({super.key});
  @override
  State<BaseRunningScreen> createState() => _BaseRunningScreenState();
}

class _BaseRunningScreenState extends State<BaseRunningScreen> {
  Timer? _t;
  final base = BaseSession.instance;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fix = GnssEngine().lastFix;
    return Scaffold(
      appBar: AppBar(title: const Text('BASE RUNNING')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('BASE RUNNING', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(base.elapsed?.toString().split('.').first ?? '00:00:00', style: const TextStyle(color: Colors.white, fontSize: 28)),
                Text(base.receiverName ?? '', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _row('Base point', base.pointName ?? '--'),
          _row('Coordinates', '${base.latitude?.toStringAsFixed(8) ?? "--"}, ${base.longitude?.toStringAsFixed(8) ?? "--"}'),
          _row('Elevation', '${base.elevation?.toStringAsFixed(3) ?? "--"} m'),
          _row('Antenna', '${base.antenna.heightM.toStringAsFixed(3)} m ${base.antenna.measureType}'),
          _row('Format', base.correctionFormat.toUpperCase()),
          _row('Output', base.correctionOutput),
          _row('Radio', base.radio.radioType),
          _row('RTCM bytes out', '${base.rtcmBytesOut}'),
          _row('RTCM msgs out', '${base.rtcmMessagesOut}'),
          _row('Receiver sats', '${fix.satellitesUsed ?? "--"}'),
          _row('Receiver solution', fix.rtkStatus),
          _row('Link', GnssService().isConnected ? 'Connected' : 'Lost'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              base.stop();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.stop),
            label: const Text('STOP BASE'),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [Expanded(child: Text(k)), Text(v, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))]),
      );
}
