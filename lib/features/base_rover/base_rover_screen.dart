import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/services/gnss_service.dart';
import '../../core/survey/base_session.dart';
import '../../core/survey/rover_session.dart';
import '../../core/survey/survey_config.dart';
import '../base/base_setup_hub.dart';
import '../rover/rover_setup_hub.dart';
import '../gnss/gnss_connection_screen.dart';
import '../receiver/receiver_manager_screen.dart';
import '../gnss_status/gnss_status_screen.dart';

/// Professional Base / Rover entry — controller configures EXTERNAL GNSS only.
class BaseRoverScreen extends StatefulWidget {
  const BaseRoverScreen({super.key});

  @override
  State<BaseRoverScreen> createState() => _BaseRoverScreenState();
}

class _BaseRoverScreenState extends State<BaseRoverScreen> {
  final _gnss = GnssService();

  @override
  Widget build(BuildContext context) {
    final connected = _gnss.isConnected;
    final base = BaseSession.instance;
    final rover = RoverSession.instance;
    final style = SurveyConfigStore.activeConfig();

    return Scaffold(
      appBar: AppBar(title: const Text('GNSS Survey Configuration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CONTROLLER ROLE', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const Text('Field Controller (not the GNSS instrument)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    connected
                        ? 'External receiver: ${_gnss.connectedDeviceName ?? "connected"}'
                        : 'No external GNSS connected',
                    style: TextStyle(color: connected ? Colors.greenAccent : Colors.orangeAccent),
                  ),
                  if (style != null)
                    Text('Active style: ${style.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The external GNSS receiver operates as BASE or ROVER.\nGeoMaster configures and monitors it.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          _modeCard(
            context,
            title: 'BASE',
            subtitle: 'Setup base point, antenna, corrections, start base on receiver',
            icon: Icons.cell_tower,
            color: Colors.indigo,
            badge: base.state == BaseSessionState.running ? 'RUNNING' : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseSetupHub())),
          ),
          _modeCard(
            context,
            title: 'ROVER',
            subtitle: 'Correction source, RTK settings, antenna, connect rover',
            icon: Icons.gps_fixed,
            color: Colors.teal,
            badge: rover.state == RoverSessionState.rtkFixed
                ? 'FIXED'
                : rover.state == RoverSessionState.rtkFloat
                    ? 'FLOAT'
                    : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoverSetupHub())),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Connect external GNSS'),
            subtitle: const Text('Bluetooth / BLE to receiver'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GnssConnectionScreen())).then((_) => setState(() {})),
          ),
          ListTile(
            leading: const Icon(Icons.router),
            title: const Text('Receiver profiles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiverManagerScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.satellite_alt),
            title: const Text('GNSS status'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GnssStatusScreen())),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
