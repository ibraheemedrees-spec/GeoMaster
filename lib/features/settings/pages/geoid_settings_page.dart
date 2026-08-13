import 'package:flutter/material.dart';
import '../../../core/geodesy/geoid_engine.dart';

class GeoidSettingsPage extends StatefulWidget {
  const GeoidSettingsPage({super.key});
  @override
  State<GeoidSettingsPage> createState() => _GeoidSettingsPageState();
}

class _GeoidSettingsPageState extends State<GeoidSettingsPage> {
  final _engine = GeoidEngine();
  final _nCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geoid')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_engine.statusLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('H = h − N\n\nWithout a loaded geoid grid or receiver undulation, orthometric height is unavailable. GeoMaster will not invent N values.'),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('No geoid model'),
            leading: Icon(_engine.activeModel == null ? Icons.radio_button_checked : Icons.radio_button_off),
            onTap: () => setState(() => _engine.clear()),
          ),
          const Divider(),
          TextField(
            controller: _nCtrl,
            decoration: const InputDecoration(labelText: 'Manual N (m) only if known from reliable source', helperText: 'Leave empty if unknown'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          ElevatedButton(
            onPressed: () {
              final n = double.tryParse(_nCtrl.text);
              if (n == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid N')));
                return;
              }
              setState(() => _engine.setSeparation(n, model: 'Manual'));
            },
            child: const Text('Apply known N'),
          ),
        ],
      ),
    );
  }
}
