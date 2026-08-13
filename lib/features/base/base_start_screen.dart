import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';
import '../../core/services/gnss_service.dart';
import 'base_running_screen.dart';

class BaseStartScreen extends StatelessWidget {
  const BaseStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final base = BaseSession.instance;
    final gnss = GnssService();
    final summary = base.summary();

    return Scaffold(
      appBar: AppBar(title: const Text('Start Base')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('CONFIRMATION SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...summary.entries.map((e) => ListTile(
                dense: true,
                title: Text(e.key),
                trailing: Text(e.value, style: const TextStyle(fontFamily: 'monospace')),
              )),
          const Divider(),
          Text(
            gnss.isConnected
                ? 'External receiver connected: ${gnss.connectedDeviceName}'
                : 'WARNING: No external GNSS connected. Base cannot start on controller alone.',
            style: TextStyle(color: gnss.isConnected ? Colors.green : Colors.red),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Putting the receiver into BASE transmit mode requires receiver firmware support (NMEA/OEM). GeoMaster records the session and configuration; it does not emulate a base radio itself.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () {
              final ok = base.start(
                receiverLabel: gnss.connectedDeviceName ?? 'GNSS',
                receiverConnected: gnss.isConnected,
              );
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(base.lastError ?? 'Cannot start')));
                return;
              }
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BaseRunningScreen()));
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('START BASE'),
          ),
        ],
      ),
    );
  }
}
