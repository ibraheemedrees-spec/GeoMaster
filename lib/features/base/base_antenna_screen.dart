import 'package:flutter/material.dart';
import '../../core/survey/base_session.dart';

class BaseAntennaScreen extends StatefulWidget {
  const BaseAntennaScreen({super.key});
  @override
  State<BaseAntennaScreen> createState() => _BaseAntennaScreenState();
}

class _BaseAntennaScreenState extends State<BaseAntennaScreen> {
  final base = BaseSession.instance;
  late TextEditingController _h;
  late TextEditingController _mfr;
  late TextEditingController _model;

  @override
  void initState() {
    super.initState();
    _h = TextEditingController(text: base.antenna.heightM.toStringAsFixed(3));
    _mfr = TextEditingController(text: base.antenna.manufacturer);
    _model = TextEditingController(text: base.antenna.model);
  }

  @override
  void dispose() {
    _h.dispose();
    _mfr.dispose();
    _model.dispose();
    super.dispose();
  }

  void _save() {
    base.antenna.heightM = double.tryParse(_h.text) ?? 0;
    base.antenna.manufacturer = _mfr.text.trim();
    base.antenna.model = _model.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base antenna saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Base Antenna'), actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _mfr, decoration: const InputDecoration(labelText: 'Antenna manufacturer')),
          TextField(controller: _model, decoration: const InputDecoration(labelText: 'Antenna model')),
          TextField(
            controller: _h,
            decoration: const InputDecoration(labelText: 'Antenna height (m)', helperText: 'Vertical or slant — do not mix'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          DropdownButtonFormField<String>(
            value: base.antenna.measureType,
            decoration: const InputDecoration(labelText: 'Measurement type'),
            items: const [
              DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
              DropdownMenuItem(value: 'slant', child: Text('Slant')),
            ],
            onChanged: (v) => setState(() => base.antenna.measureType = v ?? 'vertical'),
          ),
          const SizedBox(height: 12),
          Text(
            base.antenna.measureType == 'slant'
                ? 'Slant height stored as entered. Reduction to vertical requires antenna radius (not assumed).'
                : 'Vertical height applied directly to ARP.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
