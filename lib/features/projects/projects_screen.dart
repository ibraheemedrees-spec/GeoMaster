import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/project_model.dart';
import '../../core/theme/app_theme.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';
import 'create_project_dialog.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsBox = Hive.box<ProjectModel>('projects');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: projectsBox.listenable(),
        builder: (context, Box<ProjectModel> box, _) {
          final projects = box.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'no_projects'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'create_first_project'.tr(),
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(Icons.folder, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    project.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${project.points.length} ${'points'.tr()} • ${project.lines.length} ${'lines'.tr()} • ${project.polygons.length} ${'polygons'.tr()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        '${'last_update'.tr()}: ${_formatDate(project.updatedAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(project: project),
                      ),
                    );
                  },
                  onLongPress: () => _showProjectOptions(context, project),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: Text('new_project'.tr()),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateProjectDialog(),
    );
  }

  void _showProjectOptions(BuildContext context, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text('edit'.tr()),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO: Edit project
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  project.delete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
