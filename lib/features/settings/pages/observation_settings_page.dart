import 'package:flutter/material.dart';
import '../../../core/survey/survey_config.dart';

class ObservationSettingsPage extends StatefulWidget {
  const ObservationSettingsPage({super.key});
  @override
  State<ObservationSettingsPage> createState() => _ObservationSettingsPageState();
}

class _ObservationSettingsPageState extends State<ObservationSettingsPage> {
  SurveyConfig? _cfg;

  @override
  void initState() {
    super.initState();
    _cfg = SurveyConfigStore.activeConfig();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observation'),
        actions: [
          if (c != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                await SurveyConfigStore.saveConfig(c);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
              },
            ),
        ],
      ),
      body: c == null
          ? const Center(child: Text('Activate a Survey Configuration first'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: c.observationMethod,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'instant', child: Text('Instant')),
                    DropdownMenuItem(value: 'average', child: Text('Average')),
                    DropdownMenuItem(value: 'fixed_time', child: Text('Fixed Time')),
                    DropdownMenuItem(value: 'fixed_epochs', child: Text('Fixed Epochs')),
                  ],
                  onChanged: (v) => setState(() => c.observationMethod = v ?? c.observationMethod),
                ),
                ListTile(
                  title: Text('Duration: ${c.observationSeconds}s'),
                  subtitle: Slider(
                    value: c.observationSeconds.toDouble(),
                    min: 1,
                    max: 60,
                    onChanged: (v) => setState(() => c.observationSeconds = v.round()),
                  ),
                ),
                ListTile(
                  title: Text('Min epochs: ${c.minEpochs}'),
                  subtitle: Slider(
                    value: c.minEpochs.toDouble(),
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => c.minEpochs = v.round()),
                  ),
                ),
              ],
            ),
    );
  }
}
