import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/project_model.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _coordinateSystem = 'WGS84';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _createProject() {
    if (_formKey.currentState!.validate()) {
      final project = ProjectModel(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        coordinateSystem: _coordinateSystem,
      );

      final box = Hive.box<ProjectModel>('projects');
      box.put(project.id, project);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('new_project'.tr()),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'project_name'.tr(),
                prefixIcon: const Icon(Icons.folder),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'required_field'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'description'.tr(),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _coordinateSystem,
              decoration: InputDecoration(
                labelText: 'coordinate_system'.tr(),
                prefixIcon: const Icon(Icons.grid_on),
              ),
              items: const [
                DropdownMenuItem(value: 'WGS84', child: Text('WGS84')),
                DropdownMenuItem(value: 'UTM', child: Text('UTM')),
                DropdownMenuItem(value: 'Local', child: Text('Local Grid')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _coordinateSystem = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _createProject,
          child: Text('create'.tr()),
        ),
      ],
    );
  }
}
