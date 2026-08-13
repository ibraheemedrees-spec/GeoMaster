import 'package:flutter/material.dart';
import '../../core/survey/rover_session.dart';
import '../../core/services/gnss_service.dart';
import '../../core/services/ntrip_service.dart';
import '../ntrip/ntrip_screen.dart';
import '../gnss/gnss_connection_screen.dart';
import '../gnss_status/gnss_status_screen.dart';
import 'rover_antenna_screen.dart';
import 'rover_rtk_settings_screen.dart';
import 'rover_correction_source_screen.dart';

class RoverSetupHub extends StatefulWidget {
  const RoverSetupHub({super.key});

  @override
  State<RoverSetupHub> createState() => _RoverSetupHubState();
}

class _RoverSetupHubState extends State<RoverSetupHub> {
  final rover = RoverSession.instance;

  @override
  Widget build(BuildContext context) {
    final gnssOk = GnssService().isConnected;
    final ntripOk = NtripService().isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('ROVER Setup')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Rover = external GNSS receiving corrections. Controller configures correction source and monitors RTK quality.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          _tile(Icons.bluetooth, '1. Receiver connection', gnssOk ? 'Connected' : 'Required', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GnssConnectionScreen())).then((_) => setState(() {}));
          }),
          _tile(Icons.settings_input_antenna, '2. Antenna', '${rover.antenna.heightM.toStringAsFixed(3)} m', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RoverAntennaScreen())).then((_) => setState(() {}));
          }),
          _tile(Icons.cloud_sync, '3. Correction source', rover.correctionSource.toUpperCase(), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RoverCorrectionSourceScreen())).then((_) => setState(() {}));
          }),
          _tile(Icons.tune, '4. RTK settings', 'mask ${rover.elevationMaskDeg}° · min sats ${rover.minSatellites}', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RoverRtkSettingsScreen())).then((_) => setState(() {}));
          }),
          _tile(Icons.satellite_alt, '5. GNSS status', rover.solution ?? '—', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GnssStatusScreen()));
          }),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Link status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('GNSS receiver: ${gnssOk ? "OK" : "NOT CONNECTED"}'),
                  Text('NTRIP: ${ntripOk ? "OK" : "off"}'),
                  Text('Required solution: ${rover.requiredSolution}'),
                ],
              ),
            ),
          ),
          if (rover.correctionSource == 'ntrip')
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NtripScreen())).then((_) => setState(() {})),
              icon: const Icon(Icons.link),
              label: const Text('Open NTRIP client'),
            ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
