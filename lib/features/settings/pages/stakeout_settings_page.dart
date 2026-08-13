import 'package:flutter/material.dart';
import '../../../core/survey/survey_config.dart';

class StakeoutSettingsPage extends StatefulWidget {
  const StakeoutSettingsPage({super.key});
  @override
  State<StakeoutSettingsPage> createState() => _StakeoutSettingsPageState();
}

class _StakeoutSettingsPageState extends State<StakeoutSettingsPage> {
  SurveyConfig? _cfg;
  final options = [0.010, 0.020, 0.050, 0.100, 0.200];

  @override
  void initState() {
    super.initState();
    _cfg = SurveyConfigStore.activeConfig();
  }

  @override
  Widget build(BuildContext context) {
    final c = _cfg;
    return Scaffold(
      appBar: AppBar(title: const Text('Stakeout Settings')),
      body: c == null
          ? const Center(child: Text('Activate a Survey Configuration first'))
          : ListView(
              children: options.map((t) {
                return RadioListTile<double>(
                  title: Text('${t.toStringAsFixed(3)} m'),
                  value: t,
                  groupValue: c.stakeoutToleranceM,
                  onChanged: (v) async {
                    setState(() => c.stakeoutToleranceM = v!);
                    await SurveyConfigStore.saveConfig(c);
                  },
                );
              }).toList(),
            ),
    );
  }
}
