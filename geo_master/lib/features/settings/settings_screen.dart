import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../gnss/gnss_connection_screen.dart';
import '../ntrip/ntrip_screen.dart';
import '../auth/auth_screen.dart';
import '../base_rover/base_rover_screen.dart';
import '../../core/services/gnss_service.dart';
import '../../core/services/ntrip_service.dart';
import '../../core/services/cloud_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box settingsBox;
  final GnssService _gnssService = GnssService();
  final NtripService _ntripService = NtripService();
  final CloudSyncService _cloud = CloudSyncService();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
  }

  Future<void> _sync() async {
    if (!_cloud.isLoggedIn) {
      final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      if (ok != true) return;
    }
    setState(() => _syncing = true);
    try {
      final result = await _cloud.syncAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'sync_done'.tr()}: ↑${result['uploaded']} ↓${result['downloaded']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sync_failed'.tr())));
      }
    }
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale.languageCode;
    final isGnssConnected = _gnssService.isConnected;
    final isNtripConnected = _ntripService.isConnected;
    final isLoggedIn = _cloud.isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        children: [
          // Account / Cloud
          ListTile(
            leading: Icon(isLoggedIn ? Icons.cloud_done : Icons.cloud_off, color: isLoggedIn ? Colors.green : null),
            title: Text(isLoggedIn ? 'cloud_account'.tr() : 'login'.tr()),
            subtitle: Text(isLoggedIn ? (_cloud.currentUser?.email ?? '') : 'cloud_sync_desc'.tr()),
            trailing: isLoggedIn
                ? IconButton(icon: const Icon(Icons.logout), onPressed: () async { await _cloud.signOut(); setState(() {}); })
                : const Icon(Icons.chevron_right),
            onTap: () async {
              if (!isLoggedIn) {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                setState(() {});
              }
            },
          ),
          if (isLoggedIn)
            ListTile(
              leading: _syncing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
              title: Text('sync_now'.tr()),
              onTap: _syncing ? null : _sync,
            ),
          const Divider(),

          // Language
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
                  settingsBox.put('language', value);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: Text('units'.tr()),
            subtitle: Text('meters'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: Text('coordinate_system'.tr()),
            subtitle: Text(settingsBox.get('coord_system', defaultValue: 'WGS84')),
            trailing: DropdownButton<String>(
              value: settingsBox.get('coord_system', defaultValue: 'WGS84'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'WGS84', child: Text('WGS84')),
                DropdownMenuItem(value: 'UTM', child: Text('UTM')),
                DropdownMenuItem(value: 'Local', child: Text('Local Grid')),
              ],
              onChanged: (v) {
                if (v != null) {
                  settingsBox.put('coord_system', v);
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(isGnssConnected ? Icons.bluetooth_connected : Icons.bluetooth, color: isGnssConnected ? Colors.green : null),
            title: Text('connect_gnss'.tr()),
            subtitle: Text(isGnssConnected ? '${'connected_to'.tr()}: ${_gnssService.connectedDeviceName}' : 'not_connected'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const GnssConnectionScreen()));
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(isNtripConnected ? Icons.cloud_done : Icons.cloud, color: isNtripConnected ? Colors.green : null),
            title: Text('ntrip_settings'.tr()),
            subtitle: Text(isNtripConnected ? 'ntrip_connected'.tr() : 'ntrip_disconnected'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const NtripScreen()));
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text('base_rover_mode'.tr()),
            subtitle: Text('base_rover_desc'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BaseRoverScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('about'.tr()),
            subtitle: const Text('Geo Master v1.3.0'),
          ),
        ],
      ),
    );
  }
}
