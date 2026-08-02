import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/project_model.dart';
import 'data/models/point_model.dart';
import 'data/models/line_model.dart';
import 'data/models/polygon_model.dart';
import 'data/models/layer_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ProjectModelAdapter());
  Hive.registerAdapter(PointModelAdapter());
  Hive.registerAdapter(LineModelAdapter());
  Hive.registerAdapter(PolygonModelAdapter());
  Hive.registerAdapter(LayerModelAdapter());

  await Hive.openBox<ProjectModel>('projects');
  await Hive.openBox('settings');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const ProviderScope(
        child: GeoMasterApp(),
      ),
    ),
  );
}
