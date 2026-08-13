import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';
import '../../core/services/gnss_service.dart';
import 'base_point_screen.dart';
import 'base_antenna_screen.dart';
import 'base_corrections_screen.dart';
import 'base_radio_screen.dart';
import 'base_start_screen.dart';
import 'base_running_screen.dart';

class BaseSetupHub extends StatefulWidget {
  const BaseSetupHub({super.key});

  @override
  State<BaseSetupHub> createState() => _BaseSetupHubState();
}

class _BaseSetupHubState extends State<BaseSetupHub> {
  final base = BaseSession.instance;

  @override
  Widget build(BuildContext context) {
    final running = base.state == BaseSessionState.running;
    return Scaffold(
      appBar: AppBar(title: const Text('BASE Setup')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: running ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              running
                  ? 'BASE RUNNING on external receiver'
                  : 'Configure the EXTERNAL GNSS as Base. Controller does not act as base.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          _step(1, 'Base Point', base.hasValidCoordinates ? 'OK' : 'Required', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BasePointScreen())).then((_) => setState(() {}));
          }),
          _step(2, 'Antenna', '${base.antenna.heightM.toStringAsFixed(3)} m', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseAntennaScreen())).then((_) => setState(() {}));
          }),
          _step(3, 'Correction Output', base.correctionFormat.toUpperCase(), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseCorrectionsScreen())).then((_) => setState(() {}));
          }),
          _step(4, 'Radio / Network', base.radio.radioType, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseRadioScreen())).then((_) => setState(() {}));
          }),
          const SizedBox(height: 16),
          if (running)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseRunningScreen())),
              icon: const Icon(Icons.monitor_heart),
              label: const Text('BASE STATUS'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseStartScreen())).then((_) => setState(() {}));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('START BASE'),
            ),
          const SizedBox(height: 8),
          Text(
            'Receiver linked: ${GnssService().isConnected ? (GnssService().connectedDeviceName ?? "yes") : "NO — connect first"}',
            textAlign: TextAlign.center,
            style: TextStyle(color: GnssService().isConnected ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _step(int n, String title, String status, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$n')),
        title: Text(title),
        subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
