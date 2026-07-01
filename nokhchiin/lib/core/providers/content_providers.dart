import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/content_datasource.dart';

final contentSourceProvider = Provider((_) => ContentDataSource());
final worldsProvider = FutureProvider((ref) => ref.read(contentSourceProvider).loadWorlds());
final collectionsProvider = FutureProvider((ref) => ref.read(contentSourceProvider).loadCollections());
final storiesProvider = FutureProvider((ref) => ref.read(contentSourceProvider).loadStories());
