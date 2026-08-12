import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/survey/base_session.dart';
import '../../core/gnss/gnss_engine.dart';
import '../../data/models/project_model.dart';
import '../../data/models/point_model.dart';

class BasePointScreen extends StatefulWidget {
  const BasePointScreen({super.key});

  @override
  State<BasePointScreen> createState() => _BasePointScreenState();
}

class _BasePointScreenState extends State<BasePointScreen> {
  final base = BaseSession.instance;
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _elev = TextEditingController();
  bool _averaging = false;
  int _epochs = 0;

  @override
  void initState() {
    super.initState();
    if (base.latitude != null) {
      _lat.text = base.latitude!.toStringAsFixed(8);
      _lon.text = base.longitude!.toStringAsFixed(8);
      _elev.text = (base.elevation ?? 0).toStringAsFixed(3);
    }
  }

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _elev.dispose();
    super.dispose();
  }

  void _applyManual() {
    final la = double.tryParse(_lat.text);
    final lo = double.tryParse(_lon.text);
    final el = double.tryParse(_elev.text);
    if (la == null || lo == null || el == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid coordinates')));
      return;
    }
    setState(() => base.setManual(la, lo, el));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Base point set (manual)')));
  }

  Future<void> _average() async {
    setState(() {
      _averaging = true;
      _epochs = 0;
    });
    double sLat = 0, sLon = 0, sEl = 0;
    const n = 10;
    for (int i = 0; i < n; i++) {
      final f = await GnssEngine().getCurrentFix();
      if (f != null && f.hasPosition) {
        sLat += f.latitude!;
        sLon += f.longitude!;
        sEl += f.ellipsoidalHeight ?? 0;
        setState(() => _epochs = i + 1);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (_epochs > 0) {
      base.setAveraged(sLat / _epochs, sLon / _epochs, sEl / _epochs);
      _lat.text = base.latitude!.toStringAsFixed(8);
      _lon.text = base.longitude!.toStringAsFixed(8);
      _elev.text = base.elevation!.toStringAsFixed(3);
    }
    setState(() => _averaging = false);
  }

  Future<void> _pickKnown() async {
    final box = Hive.box<ProjectModel>('projects');
    final projects = box.values.toList();
    final points = <PointModel>[];
    for (final p in projects) {
      points.addAll(p.points);
    }
    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No project points available')));
      return;
    }
    final selected = await showDialog<PointModel>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Known Point'),
        children: points
            .map((pt) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, pt),
                  child: Text('${pt.name}  ${pt.latitude.toStringAsFixed(6)}, ${pt.longitude.toStringAsFixed(6)}'),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        base.setKnownPoint(
          id: selected.id,
          name: selected.name,
          lat: selected.latitude,
          lon: selected.longitude,
          elev: selected.altitude,
        );
        _lat.text = selected.latitude.toStringAsFixed(8);
        _lon.text = selected.longitude.toStringAsFixed(8);
        _elev.text = selected.altitude.toStringAsFixed(3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Base Point')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Point source', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Known Point'),
            subtitle: const Text('Select from project points'),
            leading: Icon(base.pointSource == BasePointSource.knownPoint ? Icons.radio_button_checked : Icons.radio_button_off),
            onTap: _pickKnown,
          ),
          ListTile(
            title: const Text('Average position'),
            subtitle: _averaging ? Text('Epochs $_epochs/10 from external/internal GNSS stream') : const Text('Average live GNSS (prefer external)'),
            leading: Icon(base.pointSource == BasePointSource.averaged ? Icons.radio_button_checked : Icons.radio_button_off),
            onTap: _averaging ? null : _average,
          ),
          ListTile(
            title: const Text('Manual entry'),
            leading: Icon(base.pointSource == BasePointSource.manual ? Icons.radio_button_checked : Icons.radio_button_off),
            onTap: () {},
          ),
          const Divider(),
          TextField(controller: _lat, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
          const SizedBox(height: 8),
          TextField(controller: _lon, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
          const SizedBox(height: 8),
          TextField(controller: _elev, decoration: const InputDecoration(labelText: 'Elevation (m)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _applyManual, child: const Text('Apply coordinates')),
          if (base.hasValidCoordinates)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Active: ${base.pointName} (${base.pointSource.name})', style: const TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }
}
