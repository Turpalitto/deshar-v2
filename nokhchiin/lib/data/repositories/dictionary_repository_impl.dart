import '../../domain/entities/word_entity.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/asset_dictionary_datasource.dart';

class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._assets);

  final AssetDictionaryDataSource _assets;
  List<WordEntity>? _cache;
  Map<String, WordEntity>? _indexById;

  Future<List<WordEntity>> _load() async {
    if (_cache == null) {
      final result = await _assets.loadBundledDictionary();
      final words = result.getOr([]);
      _cache = words;
      _indexById = {for (final w in words) w.id: w};
    }
    return _cache!;
  }

  @override
  Future<List<WordEntity>> getAllWords() => _load();

  @override
  Future<WordEntity?> getWordById(String id) async {
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
  Future<List<WordEntity>> getWordsByCategory(String category) async {
    final all = await _load();
    return all.where((w) => w.category == category).toList();
  }

  @override
  Future<List<WordEntity>> getWordsByIds(List<String> ids) async {
    await _load();
    final index = _indexById!;
    return [
      for (final id in ids)
        if (index.containsKey(id)) index[id]!,
    ];
  }
}
