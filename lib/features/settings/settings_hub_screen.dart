import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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

/// Professional survey-controller style settings hub.
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section(context, 'SURVEY', [
            _tile(context, Icons.tune, 'Survey Configuration', 'Profiles, QC, observation', const SurveyConfigListScreen()),
            _tile(context, Icons.timer, 'Observation', 'Instant / average / epochs', const ObservationSettingsPage()),
            _tile(context, Icons.verified, 'Quality Control', 'Limits & acceptance', const QualitySettingsPage()),
            _tile(context, Icons.navigation, 'Stakeout', 'Tolerance & display', const StakeoutSettingsPage()),
          ]),
          _section(context, 'GNSS / RECEIVER', [
            _tile(context, Icons.satellite_alt, 'GNSS Status', 'Live fix & quality', const GnssStatusScreen()),
            _tile(context, Icons.gps_fixed, 'Satellites', 'Sky plot & SNR', const SatellitesScreen()),
            _tile(context, Icons.router, 'Receivers', 'Profiles & active device', const ReceiverManagerScreen()),
            _tile(context, Icons.bluetooth, 'Connection', 'Bluetooth / Internal GNSS', const GnssConnectionScreen()),
            _tile(context, Icons.cloud, 'NTRIP', 'Caster & corrections', const NtripScreen()),
            _tile(context, Icons.cell_tower, 'Base / Rover', 'Role configuration', const BaseRoverScreen()),
            _tile(context, Icons.settings_input_antenna, 'Antenna', 'Height & model', const AntennaSettingsPage()),
          ]),
          _section(context, 'COORDINATE', [
            _tile(context, Icons.grid_on, 'Coordinate System', 'WGS84 / UTM / EPSG', const CoordSystemPage()),
            _tile(context, Icons.landscape, 'Geoid', 'H = h − N', const GeoidSettingsPage()),
            _tile(context, Icons.straighten, 'Units', 'Meters / feet', const UnitsSettingsPage()),
          ]),
          _section(context, 'MAP & DEVICE', [
            _tile(context, Icons.map, 'Map', 'Layers & display', const MapSettingsPage()),
            _tile(context, Icons.phone_android, 'Device', 'Capabilities', const DeviceInfoPage()),
            _tile(context, Icons.monitor_heart, 'Diagnostics', 'Connection health', const DiagnosticsScreen()),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
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

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
