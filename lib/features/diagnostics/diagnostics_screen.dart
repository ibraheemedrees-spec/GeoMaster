import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/hal/connection_manager.dart';
import '../../core/services/ntrip_service.dart';
import '../../core/services/gnss_service.dart';
import '../../core/gnss/gnss_engine.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ConnectionManager().diagnosticsSnapshot();
    final ntrip = NtripService();
    final fix = GnssEngine().lastFix;

    return Scaffold(
      appBar: AppBar(title: const Text('Connection Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _chip(d['state'] as String? ?? '—'),
          const SizedBox(height: 12),
          _row('Transport', d['transport']?.toString() ?? '--'),
          _row('Device', d['deviceName']?.toString() ?? GnssService().connectedDeviceName ?? '--'),
          _row('Bytes RX', '${d['bytesReceived']}'),
          _row('Bytes TX', '${d['bytesTransmitted']}'),
          _row('Last data', d['lastDataAt']?.toString() ?? '--'),
          _row('NMEA detected', (d['nmeaDetected'] == true) ? 'YES' : 'NO'),
          _row('RTCM detected', (d['rtcmDetected'] == true) ? 'YES' : 'NO'),
          _row('GNSS verified', (d['gnssVerified'] == true) ? 'YES' : 'NO'),
          _row('RTK verified', (d['rtkVerified'] == true) ? 'YES' : 'NO'),
          const Divider(),
          const Text('NTRIP', style: TextStyle(fontWeight: FontWeight.bold)),
          _row('Status', ntrip.isConnected ? 'Connected' : 'Disconnected'),
          _row('Caster', ntrip.caster ?? '--'),
          _row('Mountpoint', ntrip.mountpoint ?? '--'),
          _row('RTCM bytes', '${ntrip.rtcmBytesReceived}'),
          _row('RTCM msgs', '${ntrip.rtcmMessageCount}'),
          _row('Duration', ntrip.connectionDuration?.toString().split('.').first ?? '--'),
          const Divider(),
          const Text('Last Fix', style: TextStyle(fontWeight: FontWeight.bold)),
          _row('Position', fix.hasPosition ? '${fix.latStr}, ${fix.lonStr}' : '--'),
          _row('RTK', fix.rtkStatus),
          _row('H Acc', fix.horizontalAccuracy == null ? '--' : '${fix.horizontalAccuracy!.toStringAsFixed(3)} m'),
        ],
      ),
    );
  }

  Widget _chip(String state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
      child: Text(state, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
