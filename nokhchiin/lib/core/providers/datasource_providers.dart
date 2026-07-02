import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/asset_dictionary_datasource.dart';
import '../../data/datasources/local_storage_datasource.dart';

final assetDictSourceProvider = Provider((_) => AssetDictionaryDataSource());
final progressLocalProvider = Provider((_) => LocalProgressDataSource());
final userLocalProvider = Provider((_) => LocalUserDataSource());
