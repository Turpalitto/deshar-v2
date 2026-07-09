import '../../domain/entities/word_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/asset_dictionary_datasource.dart';
import '../datasources/asset_dictionary_parser.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._assets);

  final AssetDictionaryDataSource _assets;
  List<WordEntity>? _cache;
  Map<String, WordEntity>? _indexById;
  List<WordEntity>? _curatedCache;
  Map<String, WordEntity>? _curatedIndexById;
  Map<String, List<WordEntity>>? _lessonsByCategory;
  Map<String, WordEntity>? _lessonsIndexById;

  Future<List<WordEntity>> _load() async {
    if (_cache == null) {
      final result = await _assets.loadBundledDictionary();
      final words = result.getOr([]);
      _cache = words;
      _indexById = {for (final w in words) w.id: w};
    }
    return _cache!;
  }

  /// Лёгкая загрузка только curated-слов (~330 записей вместо 134k).
  /// Категории существуют только у curated-записей, поэтому для уроков,
  /// квизов и «слова дня» полный словарь не нужен — его парсинг на web
  /// блокирует UI (compute() без изолята).
  Future<void> _loadLessons() async {
    if (_lessonsByCategory != null) return;
    final raw = await _assets.loadLessonsJson();
    final lessons = raw.getOr([]);
    if (lessons.isEmpty) {
      _lessonsByCategory = {};
      _lessonsIndexById = {};
      return;
    }
    final parsed = parseLessonsFromMaps(lessons);
    _lessonsByCategory = parsed.byCategory;
    _lessonsIndexById = parsed.byId;
  }

  Future<List<WordEntity>> _loadCurated() async {
    if (_curatedCache == null) {
      final result = await _assets.loadCuratedWords();
      final words = result.getOr([]);
      _curatedCache = words;
      _curatedIndexById = {for (final w in words) w.id: w};
    }
    return _curatedCache!;
  }

  @override
  Future<List<WordEntity>> getAllWords() => _load();

  @override
  Future<List<WordEntity>> getCuratedWords() => _loadCurated();

  @override
  Future<WordEntity?> getWordById(String id) async {
    // Сначала дешёвый curated-индекс: слова уроков/SRS почти всегда оттуда.
    // Полный словарь грузим только при реальном промахе (id из экрана
    // «Словарь»).
    await _loadCurated();
    final curatedHit = _curatedIndexById?[id];
    if (curatedHit != null) return curatedHit;
    await _loadLessons();
    final lessonHit = _lessonsIndexById?[id];
    if (lessonHit != null) return lessonHit;
    await _load();
    return _indexById?[id];
  }

  @override
  Future<List<WordEntity>> search(String query,
      {String? category, PartOfSpeech? pos}) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final all = await _load();
    return all.where((w) {
      if (category != null && w.category != category) return false;
      if (pos != null && w.partOfSpeech != pos) return false;
      return w.chechen.toLowerCase().contains(q) ||
          w.russian.toLowerCase().contains(q);
    }).take(80).toList();
  }

  @override
  Future<List<WordEntity>> getLessonWords() async {
    await _loadLessons();
    return _lessonsIndexById!.values.toList();
  }

  @override
  Future<List<WordEntity>> getWordsByCategory(String category) async {
    await _loadLessons();
    final lessonWords = _lessonsByCategory![category];
    if (lessonWords != null && lessonWords.isNotEmpty) {
      return lessonWords;
    }
    // Fallback: curated для юнитов без lessons.json (adjectives, phrases, …).
    final curated = await _loadCurated();
    return curated.where((w) => w.category == category).toList();
  }

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async {
    await _loadCurated();
    await _loadLessons();
    final curatedIndex = _curatedIndexById!;
    final lessonIndex = _lessonsIndexById!;
    final result = <WordEntity>[];
    var missing = false;
    for (final id in ids) {
      final w = curatedIndex[id] ?? lessonIndex[id];
      if (w != null) {
        result.add(w);
      } else {
        missing = true;
        break;
      }
    }
    if (!missing) return result;

    // Часть id не из curated/lessons — догружаем полный индекс.
    await _load();
    final index = _indexById!;
    return [
      for (final id in ids)
        if (curatedIndex.containsKey(id))
          curatedIndex[id]!
        else if (lessonIndex.containsKey(id))
          lessonIndex[id]!
        else if (index.containsKey(id))
          index[id]!,
    ];
  }
}
