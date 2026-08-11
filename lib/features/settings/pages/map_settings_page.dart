import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});
  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  late Box box;
  bool points = true, lines = true, polygons = true, labels = true, accuracyCircle = true;

  @override
  void initState() {
    super.initState();
    box = Hive.box('settings');
    points = box.get('map_points', defaultValue: true) as bool;
    lines = box.get('map_lines', defaultValue: true) as bool;
    polygons = box.get('map_polygons', defaultValue: true) as bool;
    labels = box.get('map_labels', defaultValue: true) as bool;
    accuracyCircle = box.get('map_accuracy_circle', defaultValue: true) as bool;
  }

  Future<void> _set(String k, bool v) async {
    await box.put(k, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Base map: OpenStreetMap'), subtitle: Text('Offline tiles architecture prepared; online OSM active')),
          SwitchListTile(title: const Text('Points'), value: points, onChanged: (v) { setState(() => points = v); _set('map_points', v); }),
          SwitchListTile(title: const Text('Lines'), value: lines, onChanged: (v) { setState(() => lines = v); _set('map_lines', v); }),
          SwitchListTile(title: const Text('Polygons'), value: polygons, onChanged: (v) { setState(() => polygons = v); _set('map_polygons', v); }),
          SwitchListTile(title: const Text('Labels'), value: labels, onChanged: (v) { setState(() => labels = v); _set('map_labels', v); }),
          SwitchListTile(title: const Text('Accuracy circle'), value: accuracyCircle, onChanged: (v) { setState(() => accuracyCircle = v); _set('map_accuracy_circle', v); }),
        ],
      ),
    );
  }
}
