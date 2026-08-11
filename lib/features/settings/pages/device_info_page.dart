import 'package:flutter/material.dart';
import '../../../core/hal/device_capabilities.dart';

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});
  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  DeviceCapabilities? _cap;

  @override
  void initState() {
    super.initState();
    DeviceCapabilities.detect().then((c) {
      if (mounted) setState(() => _cap = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _cap;
    return Scaffold(
      appBar: AppBar(title: const Text('Device')),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row('Platform', c.platform),
                _row('OS version', c.androidVersion ?? '--'),
                _row('Location', c.hasLocation ? 'Available' : 'Unavailable'),
                _row('Bluetooth', c.hasBluetooth ? 'Available' : 'Unavailable'),
                _row('BLE', c.hasBle ? 'Available' : 'Unavailable'),
                _row('Wi-Fi', c.hasWifi ? 'Assumed available' : 'Unavailable'),
                _row('Network', c.hasNetwork ? 'Assumed available' : 'Unavailable'),
                const SizedBox(height: 12),
                const Text('USB Host / Serial: require runtime check per device; not assumed.', style: TextStyle(color: Colors.grey)),
              ],
            ),
    );
  }

  Widget _row(String k, String v) => ListTile(title: Text(k), trailing: Text(v));
}
