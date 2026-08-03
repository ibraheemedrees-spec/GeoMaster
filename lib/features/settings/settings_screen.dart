import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../gnss/gnss_connection_screen.dart';
import '../ntrip/ntrip_screen.dart';
import '../base_rover/base_rover_screen.dart';
import '../../core/services/gnss_service.dart';
import '../../core/services/ntrip_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Box? settingsBox;
  final GnssService _gnssService = GnssService();
  final NtripService _ntripService = NtripService();

  @override
  void initState() {
    super.initState();
    try {
      settingsBox = Hive.box('settings');
    } catch (_) {
      settingsBox = null;
    }
  }

  String get _coordSystem {
    try {
      return settingsBox?.get('coord_system', defaultValue: 'WGS84') ?? 'WGS84';
    } catch (_) {
      return 'WGS84';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final isGnssConnected = _gnssService.isConnected;
    final isNtripConnected = _ntripService.isConnected;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(currentLocale == 'ar' ? 'العربية' : 'English'),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text('units'.tr()),
            subtitle: Text('meters'.tr()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: Text('coordinate_system'.tr()),
            subtitle: Text(_coordSystem),
            trailing: DropdownButton<String>(
              value: _coordSystem,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'WGS84', child: Text('WGS84')),
                DropdownMenuItem(value: 'UTM', child: Text('UTM')),
                DropdownMenuItem(value: 'Local', child: Text('Local Grid')),
              ],
              onChanged: (v) {
                if (v != null) {
                  try {
                    settingsBox?.put('coord_system', v);
                  } catch (_) {}
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isGnssConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isGnssConnected ? Colors.green : null,
            ),
            title: Text('connect_gnss'.tr()),
            subtitle: Text(isGnssConnected ? 'connected_to'.tr() : 'not_connected'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GnssConnectionScreen()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isNtripConnected ? Icons.cloud_done : Icons.cloud,
              color: isNtripConnected ? Colors.green : null,
            ),
            title: Text('ntrip_settings'.tr()),
            subtitle: Text(isNtripConnected ? 'ntrip_connected'.tr() : 'ntrip_disconnected'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NtripScreen()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text('base_rover_mode'.tr()),
            subtitle: Text('base_rover_desc'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BaseRoverScreen()),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Geo Master'),
            subtitle: Text('v1.3.0'),
          ),
        ],
      ),
    );
  }
}
