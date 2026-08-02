import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/point_model.dart';
import '../../data/models/project_model.dart';

class EditPointScreen extends StatefulWidget {
  final ProjectModel project;
  final PointModel point;

  const EditPointScreen({super.key, required this.project, required this.point});

  @override
  State<EditPointScreen> createState() => _EditPointScreenState();
}

class _EditPointScreenState extends State<EditPointScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _altCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.point.name);
    _descCtrl = TextEditingController(text: widget.point.description);
    _latCtrl = TextEditingController(text: widget.point.latitude.toStringAsFixed(8));
    _lngCtrl = TextEditingController(text: widget.point.longitude.toStringAsFixed(8));
    _altCtrl = TextEditingController(text: widget.point.altitude.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _altCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    final alt = double.tryParse(_altCtrl.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_coordinates'.tr())));
      return;
    }

    final idx = widget.project.points.indexWhere((p) => p.id == widget.point.id);
    if (idx >= 0) {
      widget.project.points[idx] = widget.point.copyWith(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        altitude: alt ?? widget.point.altitude,
      );
      widget.project.updatedAt = DateTime.now();
      widget.project.save();
    }
    Navigator.pop(context, true);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete'.tr()),
        content: Text('confirm_delete_point'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.project.points.removeWhere((p) => p.id == widget.point.id);
              widget.project.updatedAt = DateTime.now();
              widget.project.save();
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_point'.tr()),
        actions: [
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'point_name'.tr(), prefixIcon: const Icon(Icons.label))),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: InputDecoration(labelText: 'description'.tr(), prefixIcon: const Icon(Icons.notes)), maxLines: 2),
          const SizedBox(height: 12),
          TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.my_location)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.my_location)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          TextField(controller: _altCtrl, decoration: const InputDecoration(labelText: 'Altitude (m)', prefixIcon: Icon(Icons.height)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text('save_point'.tr()),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ),
    );
  }
}
