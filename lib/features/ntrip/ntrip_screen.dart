import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/ntrip_service.dart';

class NtripScreen extends StatefulWidget {
  const NtripScreen({super.key});

  @override
  State<NtripScreen> createState() => _NtripScreenState();
}

class _NtripScreenState extends State<NtripScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '2101');
  final _mount = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _ntrip = NtripService();
  StreamSubscription? _sub;
  String _status = 'disconnected';
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _host.text = box.get('ntrip_host', defaultValue: '') as String;
    _port.text = '${box.get('ntrip_port', defaultValue: 2101)}';
    _mount.text = box.get('ntrip_mount', defaultValue: '') as String;
    _user.text = box.get('ntrip_user', defaultValue: '') as String;
    _pass.text = box.get('ntrip_pass', defaultValue: '') as String;
    _ntrip.autoReconnect = box.get('ntrip_auto_reconnect', defaultValue: true) as bool;
    _ntrip.sendGga = box.get('ntrip_send_gga', defaultValue: true) as bool;
    _ntrip.ggaIntervalSec = box.get('ntrip_gga_interval', defaultValue: 5) as int;
    _ntrip.reconnectDelaySec = box.get('ntrip_reconnect_delay', defaultValue: 5) as int;
    _status = _ntrip.isConnected ? 'connected' : 'disconnected';
    _sub = _ntrip.statusStream.listen((s) {
      if (mounted) setState(() => _status = s);
    });
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _uiTimer?.cancel();
    _host.dispose();
    _port.dispose();
    _mount.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    await box.put('ntrip_host', _host.text.trim());
    await box.put('ntrip_port', int.tryParse(_port.text) ?? 2101);
    await box.put('ntrip_mount', _mount.text.trim());
    await box.put('ntrip_user', _user.text.trim());
    await box.put('ntrip_pass', _pass.text);
    await box.put('ntrip_auto_reconnect', _ntrip.autoReconnect);
    await box.put('ntrip_send_gga', _ntrip.sendGga);
    await box.put('ntrip_gga_interval', _ntrip.ggaIntervalSec);
    await box.put('ntrip_reconnect_delay', _ntrip.reconnectDelaySec);
  }

  Future<void> _connect() async {
    await _save();
    final ok = await _ntrip.connect(
      host: _host.text.trim(),
      port: int.tryParse(_port.text) ?? 2101,
      mountpoint: _mount.text.trim(),
      username: _user.text.trim(),
      password: _pass.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'ntrip_connected'.tr() : 'connection_failed'.tr()),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ntrip.isConnected;
    return Scaffold(
      appBar: AppBar(title: Text('ntrip_settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: connected ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: connected ? Colors.green : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(connected ? Icons.cloud_done : Icons.cloud_off, color: connected ? Colors.green : Colors.grey, size: 36),
                Text(connected ? 'CONNECTED' : 'DISCONNECTED', style: TextStyle(fontWeight: FontWeight.bold, color: connected ? Colors.green : Colors.grey)),
                if (connected) ...[
                  Text('Caster: ${_ntrip.caster ?? "--"}'),
                  Text('Mount: ${_ntrip.mountpoint ?? "--"}'),
                  Text('RTCM bytes: ${_ntrip.rtcmBytesReceived}'),
                  Text('RTCM msgs: ${_ntrip.rtcmMessageCount}'),
                  Text('Duration: ${_ntrip.connectionDuration?.toString().split('.').first ?? "--"}'),
                  Text('Corr age: ${_ntrip.lastCorrectionAgeSec?.toStringAsFixed(1) ?? "--"} s'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _host, decoration: const InputDecoration(labelText: 'Caster host', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _port, decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: _mount, decoration: const InputDecoration(labelText: 'Mountpoint', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
          SwitchListTile(title: const Text('Auto reconnect'), value: _ntrip.autoReconnect, onChanged: (v) => setState(() => _ntrip.autoReconnect = v)),
          SwitchListTile(title: const Text('Send GGA'), value: _ntrip.sendGga, onChanged: (v) => setState(() => _ntrip.sendGga = v)),
          ListTile(
            title: Text('GGA interval: ${_ntrip.ggaIntervalSec}s'),
            subtitle: Slider(
              value: _ntrip.ggaIntervalSec.toDouble(),
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _ntrip.ggaIntervalSec = v.round()),
            ),
          ),
          ListTile(
            title: Text('Reconnect delay: ${_ntrip.reconnectDelaySec}s'),
            subtitle: Slider(
              value: _ntrip.reconnectDelaySec.toDouble(),
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _ntrip.reconnectDelaySec = v.round()),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: connected ? null : _connect,
                  icon: const Icon(Icons.link),
                  label: Text('connect'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: connected ? () => _ntrip.disconnect(reconnect: false) : null,
                  icon: const Icon(Icons.link_off),
                  label: Text('disconnect'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
