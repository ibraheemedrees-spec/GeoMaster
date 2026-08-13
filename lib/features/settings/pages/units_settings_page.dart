import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UnitsSettingsPage extends StatefulWidget {
  const UnitsSettingsPage({super.key});
  @override
  State<UnitsSettingsPage> createState() => _UnitsSettingsPageState();
}

class _UnitsSettingsPageState extends State<UnitsSettingsPage> {
  String _u = 'm';

  @override
  void initState() {
    super.initState();
    _u = Hive.box('settings').get('units', defaultValue: 'm') as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      body: Column(
        children: [
          RadioListTile<String>(title: const Text('Meters'), value: 'm', groupValue: _u, onChanged: (v) async {
            setState(() => _u = v!);
            await Hive.box('settings').put('units', _u);
          }),
          RadioListTile<String>(title: const Text('Feet'), value: 'ft', groupValue: _u, onChanged: (v) async {
            setState(() => _u = v!);
            await Hive.box('settings').put('units', _u);
          }),
        ],
      ),
    );
  }
}
