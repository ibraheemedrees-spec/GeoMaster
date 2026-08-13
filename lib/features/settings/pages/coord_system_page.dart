import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/geodesy/coord_system.dart';

class CoordSystemPage extends StatefulWidget {
  const CoordSystemPage({super.key});
  @override
  State<CoordSystemPage> createState() => _CoordSystemPageState();
}

class _CoordSystemPageState extends State<CoordSystemPage> {
  String _active = 'wgs84';
  String _q = '';
  List<String> _fav = [];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _active = box.get('coord_system_id', defaultValue: 'wgs84') as String;
    _fav = List<String>.from(box.get('coord_favorites', defaultValue: <String>[]) as List);
  }

  Future<void> _select(CoordSystemDef s) async {
    setState(() => _active = s.id);
    await Hive.box('settings').put('coord_system_id', s.id);
    await Hive.box('settings').put('coord_system', s.name);
  }

  @override
  Widget build(BuildContext context) {
    final list = CoordSystemCatalog.builtIn.where((e) => _q.isEmpty || e.name.toLowerCase().contains(_q.toLowerCase()) || (e.epsg ?? '').contains(_q)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Coordinate System')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or EPSG'),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView(
              children: list.map((s) {
                final selected = s.id == _active;
                return ListTile(
                  leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                  title: Text(s.name),
                  subtitle: Text('${s.epsg ?? s.type} • ${s.datum ?? ""}'),
                  trailing: IconButton(
                    icon: Icon(_fav.contains(s.id) ? Icons.star : Icons.star_border),
                    onPressed: () async {
                      setState(() {
                        if (_fav.contains(s.id)) {
                          _fav.remove(s.id);
                        } else {
                          _fav.add(s.id);
                        }
                      });
                      await Hive.box('settings').put('coord_favorites', _fav);
                    },
                  ),
                  onTap: () => _select(s),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
