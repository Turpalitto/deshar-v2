import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/core/result.dart';
import '../../domain/entities/word_entity.dart';
import '../../core/utils/app_logger.dart';
import 'asset_dictionary_parser.dart';

class AssetDictionaryDataSource {
  /// Загрузка словаря с error handling.
  /// Возвращает Result — Success(List<WordEntity>) или Failure.
  Future<Result<List<WordEntity>>> loadBundledDictionary() async {
    try {
      final curatedRaw = await rootBundle.loadString('assets/data/curated_vocabulary.json');
      final dictRaw = await rootBundle.loadString('assets/data/dictionary.json');

      final words = await compute(parseBundledDictionaryIsolate, {
        'curated': curatedRaw,
        'dictionary': dictRaw,
      });
      return Success(words);
    } catch (e, st) {
      AppLogger.error('Failed to load bundled dictionary', error: e, stackTrace: st);
      return Failure(e, st);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> loadLessonsJson() async {
    try {
      final raw = await rootBundle.loadString('assets/data/lessons.json');
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
      return Success(list);
    } catch (e, st) {
      AppLogger.error('Failed to load lessons.json', error: e, stackTrace: st);
      return Failure(e, st);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> loadLearningPathJson() async {
    try {
      final raw = await rootBundle.loadString('assets/data/learning_path.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(data['units'] as List);
      return Success(list);
    } catch (e, st) {
      AppLogger.error('Failed to load learning_path.json', error: e, stackTrace: st);
      return Failure(e, st);
    }
  }
}
