import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/project_model.dart';
import '../../data/models/layer_model.dart';

class LayersScreen extends StatefulWidget {
  final ProjectModel project;

  const LayersScreen({super.key, required this.project});

  @override
  State<LayersScreen> createState() => _LayersScreenState();
}

class _LayersScreenState extends State<LayersScreen> {
  void _addLayer() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('new_layer'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'layer_name'.tr()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  widget.project.layers.add(LayerModel(name: controller.text.trim()));
                  widget.project.updatedAt = DateTime.now();
                  widget.project.save();
                });
              }
              Navigator.pop(ctx);
            },
            child: Text('create'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('layers'.tr())),
      body: widget.project.layers.isEmpty
          ? Center(child: Text('no_layers'.tr()))
          : ListView.builder(
              itemCount: widget.project.layers.length,
              itemBuilder: (context, index) {
                final layer = widget.project.layers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(layer.colorValue),
                    radius: 12,
                  ),
                  title: Text(layer.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: layer.visible,
                        onChanged: (v) {
                          setState(() {
                            layer.visible = v;
                            widget.project.save();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            widget.project.layers.removeAt(index);
                            widget.project.save();
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLayer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
