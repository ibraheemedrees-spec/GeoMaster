import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/gnss/quality_control.dart';
import '../../../core/survey/survey_config.dart';

class QualitySettingsPage extends StatefulWidget {
  const QualitySettingsPage({super.key});
  @override
  State<QualitySettingsPage> createState() => _QualitySettingsPageState();
}

class _QualitySettingsPageState extends State<QualitySettingsPage> {
  late QualityLimits _q;
  SurveyConfig? _cfg;

  @override
  void initState() {
    super.initState();
    _cfg = SurveyConfigStore.activeConfig();
    _q = _cfg?.quality ?? QualityLimits();
  }

  Future<void> _save() async {
    if (_cfg != null) {
      _cfg!.quality = _q;
      await SurveyConfigStore.saveConfig(_cfg!);
    } else {
      final box = Hive.box('settings');
      await box.put('qc_limits', _q.toMap());
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quality Control'), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _num('Min satellites', _q.minSatellites.toDouble(), 1, 30, (v) => setState(() => _q.minSatellites = v.round())),
          _num('Max PDOP', _q.maxPdop, 0.5, 20, (v) => setState(() => _q.maxPdop = v)),
          _num('Max H accuracy (m)', _q.maxHAccuracy, 0.005, 50, (v) => setState(() => _q.maxHAccuracy = v)),
          _num('Max V accuracy (m)', _q.maxVAccuracy, 0.005, 50, (v) => setState(() => _q.maxVAccuracy = v)),
          _num('Max corr age (s)', _q.maxCorrAgeSec, 1, 60, (v) => setState(() => _q.maxCorrAgeSec = v)),
          SwitchListTile(
            title: const Text('Require RTK FIXED'),
            value: _q.requireRtkFixed,
            onChanged: (v) => setState(() => _q.requireRtkFixed = v),
          ),
        ],
      ),
    );
  }

  Widget _num(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      trailing: Text(value.toStringAsFixed(value >= 1 ? 1 : 3)),
    );
  }
}
