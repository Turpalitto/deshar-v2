import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'data/datasources/local_storage_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalProgressDataSource().init();
  await LocalUserDataSource().init();
  runApp(const ProviderScope(child: NokhchiinApp()));
}
