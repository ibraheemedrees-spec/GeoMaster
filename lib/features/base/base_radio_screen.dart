import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';

class BaseRadioScreen extends StatefulWidget {
  const BaseRadioScreen({super.key});
  @override
  State<BaseRadioScreen> createState() => _BaseRadioScreenState();
}

class _BaseRadioScreenState extends State<BaseRadioScreen> {
  final base = BaseSession.instance;
  late TextEditingController _ch;
  late TextEditingController _host;
  late TextEditingController _port;

  @override
  void initState() {
    super.initState();
    _ch = TextEditingController(text: base.radio.channel ?? '');
    _host = TextEditingController(text: base.radio.tcpHost ?? '');
    _port = TextEditingController(text: '${base.radio.tcpPort ?? 2101}');
  }

  @override
  void dispose() {
    _ch.dispose();
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = base.radio;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Base Radio / Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              r.channel = _ch.text.trim().isEmpty ? null : _ch.text.trim();
              r.tcpHost = _host.text.trim().isEmpty ? null : _host.text.trim();
              r.tcpPort = int.tryParse(_port.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Radio settings are stored for the workflow. Actual transmit depends on receiver hardware. Unsupported options stay inactive.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          DropdownButtonFormField<String>(
            value: r.radioType,
            decoration: const InputDecoration(labelText: 'Radio type'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('None')),
              DropdownMenuItem(value: 'internal', child: Text('Internal radio')),
              DropdownMenuItem(value: 'external', child: Text('External radio')),
              DropdownMenuItem(value: 'bluetooth', child: Text('Bluetooth radio')),
              DropdownMenuItem(value: 'serial', child: Text('Serial')),
              DropdownMenuItem(value: 'usb', child: Text('USB')),
              DropdownMenuItem(value: 'tcp', child: Text('TCP/IP')),
              DropdownMenuItem(value: 'network', child: Text('Network')),
            ],
            onChanged: (v) => setState(() => r.radioType = v ?? 'none'),
          ),
          TextField(controller: _ch, decoration: const InputDecoration(labelText: 'Channel')),
          ListTile(
            title: Text('Baud: ${r.baudRate}'),
            subtitle: Slider(
              value: r.baudRate.toDouble().clamp(4800, 115200),
              min: 4800,
              max: 115200,
              divisions: 20,
              onChanged: (v) => setState(() => r.baudRate = v.round()),
            ),
          ),
          TextField(controller: _host, decoration: const InputDecoration(labelText: 'TCP host (if network)')),
          TextField(controller: _port, decoration: const InputDecoration(labelText: 'TCP port'), keyboardType: TextInputType.number),
          SwitchListTile(
            title: const Text('Marked supported by current receiver'),
            subtitle: const Text('Enable only when device docs confirm radio'),
            value: r.supportedByReceiver,
            onChanged: (v) => setState(() => r.supportedByReceiver = v),
          ),
        ],
      ),
    );
  }
}
