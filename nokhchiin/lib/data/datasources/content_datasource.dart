import 'package:flutter/services.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/content_entities.dart';
import '../../domain/entities/culture_capsule.dart';
import 'content_parse_exception.dart';
import 'content_parser.dart';

class ContentDataSource {
  Future<List<CultureCapsule>> loadCultureCapsules() => _loadList(
    asset: 'assets/data/culture_capsules.json',
    label: 'culture capsules',
    parse: parseCultureCapsules,
  );

  Future<List<WorldEntity>> loadWorlds() => _loadList(
    asset: 'assets/data/worlds.json',
    label: 'worlds',
    parse: parseWorlds,
  );

  Future<List<CollectionEntity>> loadCollections() => _loadList(
    asset: 'assets/data/collections.json',
    label: 'collections',
    parse: parseCollections,
  );

  Future<List<ChestEntity>> loadChests() async {
    try {
      final raw = await rootBundle.loadString('assets/data/collections.json');
      return parseChests(raw);
    } on ContentParseException catch (e, st) {
      AppLogger.error('Failed to parse chests', error: e, stackTrace: st);
      return [];
    } catch (e, st) {
      AppLogger.error('Failed to load chests', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<StoryEntity>> loadStories() => _loadList(
    asset: 'assets/data/stories.json',
    label: 'stories',
    parse: parseStories,
  );

  Future<StoryEntity?> loadStory(String id) async {
    final all = await loadStories();
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e, st) {
      AppLogger.warn('Story not found by id: $id', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<BossEntity>> loadBosses() => _loadList(
    asset: 'assets/data/bosses.json',
    label: 'bosses',
    parse: parseBosses,
  );

  Future<BossEntity?> loadBossForUnit(String unitId) async {
    final all = await loadBosses();
    try {
      return all.firstWhere((b) => b.unitId == unitId);
    } catch (e, st) {
      AppLogger.warn(
        'Boss not found for unit: $unitId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<List<T>> _loadList<T>({
    required String asset,
    required String label,
    required List<T> Function(String raw) parse,
  }) async {
    try {
      final raw = await rootBundle.loadString(asset);
      return parse(raw);
    } on ContentParseException catch (e, st) {
      AppLogger.error('Failed to parse $label', error: e, stackTrace: st);
      return [];
    } catch (e, st) {
      AppLogger.error('Failed to load $label', error: e, stackTrace: st);
      return [];
    }
  }
}
