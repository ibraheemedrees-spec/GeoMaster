import 'package:flutter/material.dart';
import '../../core/survey/rover_session.dart';
import '../../core/survey/survey_config.dart';

class RoverRtkSettingsScreen extends StatefulWidget {
  const RoverRtkSettingsScreen({super.key});
  @override
  State<RoverRtkSettingsScreen> createState() => _RoverRtkSettingsScreenState();
}

class _RoverRtkSettingsScreenState extends State<RoverRtkSettingsScreen> {
  final rover = RoverSession.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rover RTK Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final cfg = SurveyConfigStore.activeConfig();
              if (cfg != null) {
                cfg.quality.minSatellites = rover.minSatellites;
                cfg.quality.maxPdop = rover.maxPdop;
                cfg.quality.maxCorrAgeSec = rover.maxCorrAgeSec;
                cfg.quality.requireRtkFixed = rover.requiredSolution == 'FIXED';
                await SurveyConfigStore.saveConfig(cfg);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('RTK settings saved')));
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Elevation mask: ${rover.elevationMaskDeg.toStringAsFixed(0)}°'),
            subtitle: Slider(
              value: rover.elevationMaskDeg,
              min: 0,
              max: 30,
              onChanged: (v) => setState(() => rover.elevationMaskDeg = v),
            ),
          ),
          ListTile(
            title: Text('Min satellites: ${rover.minSatellites}'),
            subtitle: Slider(
              value: rover.minSatellites.toDouble(),
              min: 4,
              max: 20,
              onChanged: (v) => setState(() => rover.minSatellites = v.round()),
            ),
          ),
          ListTile(
            title: Text('Max PDOP: ${rover.maxPdop.toStringAsFixed(1)}'),
            subtitle: Slider(
              value: rover.maxPdop,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => rover.maxPdop = v),
            ),
          ),
          ListTile(
            title: Text('Max correction age: ${rover.maxCorrAgeSec.toStringAsFixed(0)} s'),
            subtitle: Slider(
              value: rover.maxCorrAgeSec,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => rover.maxCorrAgeSec = v),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Required solution'), dense: true),
          ...['SINGLE', 'DGPS', 'FLOAT', 'FIXED'].map((s) {
            return RadioListTile<String>(
              title: Text(s),
              value: s,
              groupValue: rover.requiredSolution,
              onChanged: (v) => setState(() => rover.requiredSolution = v!),
            );
          }),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Elevation mask / constellation control on the receiver requires OEM or documented NMEA commands. Limits here drive GeoMaster quality gates for surveying.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
