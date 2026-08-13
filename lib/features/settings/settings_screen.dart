import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../gnss/gnss_connection_screen.dart';
import '../ntrip/ntrip_screen.dart';
import '../base_rover/base_rover_screen.dart';
import '../satellites/satellites_screen.dart';
import '../gnss_status/gnss_status_screen.dart';
import '../receiver/receiver_manager_screen.dart';
import '../survey_config/survey_config_list_screen.dart';
import '../diagnostics/diagnostics_screen.dart';
import 'pages/quality_settings_page.dart';
import 'pages/antenna_settings_page.dart';
import 'pages/coord_system_page.dart';
import 'pages/geoid_settings_page.dart';
import 'pages/observation_settings_page.dart';
import 'pages/device_info_page.dart';
import 'pages/units_settings_page.dart';
import 'pages/map_settings_page.dart';
import 'pages/stakeout_settings_page.dart';
import '../../core/services/gnss_service.dart';
import '../../core/services/ntrip_service.dart';

/// ACTIVE Settings screen used by the running application.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Box? settingsBox;
  final GnssService _gnss = GnssService();
  final NtripService _ntrip = NtripService();

  @override
  void initState() {
    super.initState();
    try {
      settingsBox = Hive.box('settings');
    } catch (_) {
      settingsBox = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final gnssOk = _gnss.isConnected;
    final ntripOk = _ntrip.isConnected;

    return Scaffold(
      appBar: AppBar(
        // VISIBLE TEST — must appear in APK
        title: const Text('GeoMaster Professional Survey Controller'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ========== VISIBLE INTEGRATION TEST CARD ==========
          Card(
            color: const Color(0xFF0D47A1),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'GNSS SURVEY CONTROLLER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Base / Rover', style: TextStyle(color: Colors.white70)),
                  const Text('Receiver', style: TextStyle(color: Colors.white70)),
                  const Text('RTK', style: TextStyle(color: Colors.white70)),
                  const Text('Coordinate System', style: TextStyle(color: Colors.white70)),
                  const Text('Geoid', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D47A1),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BaseRoverScreen()),
                      );
                    },
                    child: const Text(
                      'OPEN GNSS SURVEY SETTINGS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ====================================================
          const SizedBox(height: 8),
          _section('SURVEY', [
            _tile(Icons.tune, 'Survey Configuration', () => const SurveyConfigListScreen()),
            _tile(Icons.timer, 'Observation', () => const ObservationSettingsPage()),
            _tile(Icons.verified, 'Quality Control', () => const QualitySettingsPage()),
            _tile(Icons.navigation, 'Stakeout', () => const StakeoutSettingsPage()),
          ]),
          _section('GNSS / RECEIVER', [
            _tile(Icons.satellite_alt, 'GNSS Status', () => const GnssStatusScreen()),
            _tile(Icons.gps_fixed, 'Satellites', () => const SatellitesScreen()),
            _tile(Icons.router, 'Receivers', () => const ReceiverManagerScreen()),
            _tile(
              gnssOk ? Icons.bluetooth_connected : Icons.bluetooth,
              'Connection',
              () => const GnssConnectionScreen(),
              subtitle: gnssOk ? 'Connected' : 'Not connected',
            ),
            _tile(
              ntripOk ? Icons.cloud_done : Icons.cloud,
              'NTRIP',
              () => const NtripScreen(),
              subtitle: ntripOk ? 'Connected' : 'Disconnected',
            ),
            _tile(Icons.cell_tower, 'Base / Rover', () => const BaseRoverScreen()),
            _tile(Icons.settings_input_antenna, 'Antenna', () => const AntennaSettingsPage()),
          ]),
          _section('COORDINATE', [
            _tile(Icons.grid_on, 'Coordinate System', () => const CoordSystemPage()),
            _tile(Icons.landscape, 'Geoid', () => const GeoidSettingsPage()),
            _tile(Icons.straighten, 'Units', () => const UnitsSettingsPage()),
          ]),
          _section('MAP & DEVICE', [
            _tile(Icons.map, 'Map', () => const MapSettingsPage()),
            _tile(Icons.phone_android, 'Device', () => const DeviceInfoPage()),
            _tile(Icons.monitor_heart, 'Diagnostics', () => const DiagnosticsScreen()),
          ]),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            trailing: DropdownButton<String>(
              value: currentLocale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.setLocale(Locale(value));
                  try {
                    settingsBox?.put('language', value);
                  } catch (_) {}
                }
              },
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Geo Master'),
            subtitle: Text('v1.5.1 — Professional Survey Controller'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5)),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, Widget Function() page, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
    );
  }
}
