import 'package:flutter/material.dart';
import '../../../core/survey/antenna_config.dart';
import '../../../core/survey/survey_config.dart';

class AntennaSettingsPage extends StatefulWidget {
  const AntennaSettingsPage({super.key});
  @override
  State<AntennaSettingsPage> createState() => _AntennaSettingsPageState();
}

class _AntennaSettingsPageState extends State<AntennaSettingsPage> {
  late AntennaConfig _a;
  SurveyConfig? _cfg;
  late TextEditingController _mfr;
  late TextEditingController _model;
  late TextEditingController _h;

  @override
  void initState() {
    super.initState();
    _cfg = SurveyConfigStore.activeConfig();
    _a = _cfg?.antenna ?? AntennaConfig();
    _mfr = TextEditingController(text: _a.manufacturer);
    _model = TextEditingController(text: _a.model);
    _h = TextEditingController(text: _a.heightM.toStringAsFixed(3));
  }

  @override
  void dispose() {
    _mfr.dispose();
    _model.dispose();
    _h.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _a.manufacturer = _mfr.text.trim();
    _a.model = _model.text.trim();
    _a.heightM = double.tryParse(_h.text) ?? 0;
    if (_cfg != null) {
      _cfg!.antenna = _a;
      await SurveyConfigStore.saveConfig(_cfg!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Antenna saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antenna'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _mfr, decoration: const InputDecoration(labelText: 'Manufacturer')),
          TextField(controller: _model, decoration: const InputDecoration(labelText: 'Model')),
          TextField(
            controller: _h,
            decoration: const InputDecoration(labelText: 'Antenna height (m)', suffixText: 'm'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          DropdownButtonFormField<String>(
            value: _a.measureType,
            decoration: const InputDecoration(labelText: 'Measurement type'),
            items: const [
              DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
              DropdownMenuItem(value: 'slant', child: Text('Slant')),
            ],
            onChanged: (v) => setState(() => _a.measureType = v ?? 'vertical'),
          ),
          const SizedBox(height: 12),
          Text(
            'ARP/phase-center: ${_a.arpToPhaseCenterM?.toStringAsFixed(4) ?? "not set"}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
