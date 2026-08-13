export 'settings_screen.dart' show SettingsScreen;

import 'package:flutter/material.dart';
import 'settings_screen.dart';

/// Alias kept for older navigation imports.
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
