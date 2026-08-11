import 'package:flutter/material.dart';
import '../../core/survey/survey_config.dart';
import '../../core/gnss/quality_control.dart';

class SurveyConfigListScreen extends StatefulWidget {
  const SurveyConfigListScreen({super.key});

  @override
  State<SurveyConfigListScreen> createState() => _SurveyConfigListScreenState();
}

class _SurveyConfigListScreenState extends State<SurveyConfigListScreen> {
  List<SurveyConfig> _list = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _list = SurveyConfigStore.allConfigs());

  Future<void> _createDefaultsIfEmpty() async {
    if (_list.isNotEmpty) return;
    final defaults = [
      SurveyConfig(name: 'Standalone GNSS', correctionSource: 'none'),
      SurveyConfig(
        name: 'RTK Rover - NTRIP',
        correctionSource: 'ntrip',
        quality: QualityLimits(requireRtkFixed: true, maxHAccuracy: 0.02),
      ),
      SurveyConfig(name: 'RTK Base', correctionSource: 'base'),
    ];
    for (final c in defaults) {
      await SurveyConfigStore.saveConfig(c);
    }
    _reload();
  }

  Future<void> _edit(SurveyConfig c) async {
    final nameCtrl = TextEditingController(text: c.name);
    var method = c.observationMethod;
    var corr = c.correctionSource;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setL) => AlertDialog(
          title: const Text('Survey Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                DropdownButtonFormField<String>(
                  value: corr,
                  decoration: const InputDecoration(labelText: 'Correction source'),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None / Standalone')),
                    DropdownMenuItem(value: 'ntrip', child: Text('NTRIP')),
                    DropdownMenuItem(value: 'radio', child: Text('Radio (future)')),
                    DropdownMenuItem(value: 'tcp', child: Text('TCP/IP')),
                    DropdownMenuItem(value: 'base', child: Text('Base')),
                  ],
                  onChanged: (v) => setL(() => corr = v ?? corr),
                ),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Observation'),
                  items: const [
                    DropdownMenuItem(value: 'instant', child: Text('Instant')),
                    DropdownMenuItem(value: 'average', child: Text('Average')),
                    DropdownMenuItem(value: 'fixed_time', child: Text('Fixed Time')),
                    DropdownMenuItem(value: 'fixed_epochs', child: Text('Fixed Epochs')),
                  ],
                  onChanged: (v) => setL(() => method = v ?? method),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true) {
      c.name = nameCtrl.text.trim().isEmpty ? c.name : nameCtrl.text.trim();
      c.correctionSource = corr;
      c.observationMethod = method;
      await SurveyConfigStore.saveConfig(c);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Configurations'),
        actions: [
          IconButton(icon: const Icon(Icons.playlist_add), onPressed: _createDefaultsIfEmpty),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final c = SurveyConfig(name: 'New Configuration');
          await SurveyConfigStore.saveConfig(c);
          _reload();
          await _edit(c);
        },
        child: const Icon(Icons.add),
      ),
      body: _list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No configurations'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _createDefaultsIfEmpty, child: const Text('Create defaults')),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final c = _list[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.tune, color: c.isActive ? Colors.green : null),
                    title: Text(c.name),
                    subtitle: Text(
                      '${c.correctionSource} • ${c.observationMethod}\n'
                      'QC: minSats=${c.quality.minSatellites} maxH=${c.quality.maxHAccuracy}m',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'active') {
                          await SurveyConfigStore.setActiveConfig(c.id);
                          _reload();
                        } else if (v == 'edit') {
                          await _edit(c);
                        } else if (v == 'dup') {
                          await SurveyConfigStore.saveConfig(c.duplicate());
                          _reload();
                        } else if (v == 'delete') {
                          await SurveyConfigStore.deleteConfig(c.id);
                          _reload();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'active', child: Text('Activate')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
