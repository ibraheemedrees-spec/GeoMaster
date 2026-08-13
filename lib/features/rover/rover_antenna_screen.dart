import 'package:flutter/material.dart';
import '../../core/survey/rover_session.dart';
import '../../core/survey/survey_config.dart';

class RoverAntennaScreen extends StatefulWidget {
  const RoverAntennaScreen({super.key});
  @override
  State<RoverAntennaScreen> createState() => _RoverAntennaScreenState();
}

class _RoverAntennaScreenState extends State<RoverAntennaScreen> {
  final rover = RoverSession.instance;
  late TextEditingController _h;

  @override
  void initState() {
    super.initState();
    final cfg = SurveyConfigStore.activeConfig();
    if (cfg != null) rover.antenna = cfg.antenna;
    _h = TextEditingController(text: rover.antenna.heightM.toStringAsFixed(3));
  }

  @override
  void dispose() {
    _h.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rover Antenna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              rover.antenna.heightM = double.tryParse(_h.text) ?? 0;
              final cfg = SurveyConfigStore.activeConfig();
              if (cfg != null) {
                cfg.antenna = rover.antenna;
                SurveyConfigStore.saveConfig(cfg);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _h, decoration: const InputDecoration(labelText: 'Antenna height (m)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          DropdownButtonFormField<String>(
            value: rover.antenna.measureType,
            decoration: const InputDecoration(labelText: 'Measurement type'),
            items: const [
              DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
              DropdownMenuItem(value: 'slant', child: Text('Slant')),
            ],
            onChanged: (v) => setState(() => rover.antenna.measureType = v ?? 'vertical'),
          ),
        ],
      ),
    );
  }
}
