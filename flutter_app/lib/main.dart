import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/parks/data/datasources/parks_local_data_source.dart';
import 'features/species/data/datasources/species_local_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local persistence: Hive boxes back the offline cache for every feature.
  // No custom TypeAdapters are needed since we only store JSON-safe
  // Map/List/primitive data (see each *LocalDataSource for details).
  await Hive.initFlutter();
  await Hive.openBox(AuthLocalDataSourceImpl.boxName);
  await Hive.openBox(ParksLocalDataSourceImpl.boxName);
  await Hive.openBox(SpeciesLocalDataSourceImpl.boxName);

  await di.initDependencies();

  runApp(const MadaExplorerApp());
}
