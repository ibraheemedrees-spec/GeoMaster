import 'package:flutter/material.dart';
import '../../core/survey/receiver_profile.dart';
import '../../core/survey/survey_config.dart';
import '../../core/hal/connection_types.dart';

class ReceiverManagerScreen extends StatefulWidget {
  const ReceiverManagerScreen({super.key});

  @override
  State<ReceiverManagerScreen> createState() => _ReceiverManagerScreenState();
}

class _ReceiverManagerScreenState extends State<ReceiverManagerScreen> {
  List<ReceiverProfile> _list = [];
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _list = SurveyConfigStore.allReceivers();
      _activeId = SurveyConfigStore.activeReceiverId;
    });
  }

  Future<void> _edit([ReceiverProfile? existing]) async {
    final r = existing ??
        ReceiverProfile(name: 'GNSS Receiver', manufacturer: 'Generic', model: 'NMEA');
    final nameCtrl = TextEditingController(text: r.name);
    final mfrCtrl = TextEditingController(text: r.manufacturer);
    final modelCtrl = TextEditingController(text: r.model);
    final snCtrl = TextEditingController(text: r.serialNumber ?? '');
    var type = r.connectionType;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Receiver' : 'Edit Receiver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: mfrCtrl, decoration: const InputDecoration(labelText: 'Manufacturer')),
                TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
                TextField(controller: snCtrl, decoration: const InputDecoration(labelText: 'Serial Number')),
                DropdownButtonFormField<ConnectionType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Connection'),
                  items: ConnectionType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (v) => setLocal(() => type = v ?? type),
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
      r.name = nameCtrl.text.trim().isEmpty ? r.name : nameCtrl.text.trim();
      r.manufacturer = mfrCtrl.text.trim();
      r.model = modelCtrl.text.trim();
      r.serialNumber = snCtrl.text.trim().isEmpty ? null : snCtrl.text.trim();
      r.connectionType = type;
      await SurveyConfigStore.saveReceiver(r);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receivers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _list.isEmpty
          ? const Center(child: Text('No receivers yet.\nAdd a Generic NMEA profile.'))
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final r = _list[i];
                final active = r.id == _activeId;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(Icons.gps_fixed, color: active ? Colors.green : null),
                    title: Text(r.name),
                    subtitle: Text('${r.manufacturer} ${r.model}\n${r.connectionType.label}'),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'active') {
                          await SurveyConfigStore.setActiveReceiver(r.id);
                          _reload();
                        } else if (v == 'edit') {
                          await _edit(r);
                        } else if (v == 'delete') {
                          await SurveyConfigStore.deleteReceiver(r.id);
                          _reload();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'active', child: Text('Set Active')),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
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
