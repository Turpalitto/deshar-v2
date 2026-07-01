import 'dart:convert';
import 'package:flutter/services.dart';

class ContentDataSource {
  Future<List<Map<String, dynamic>>> loadWorlds() async {
    final raw = await rootBundle.loadString('assets/data/worlds.json');
    return List<Map<String, dynamic>>.from(jsonDecode(raw)['worlds'] as List);
  }

  Future<List<Map<String, dynamic>>> loadCollections() async {
    final raw = await rootBundle.loadString('assets/data/collections.json');
    final d = jsonDecode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(d['collections'] as List);
  }

  Future<List<Map<String, dynamic>>> loadChests() async {
    final raw = await rootBundle.loadString('assets/data/collections.json');
    final d = jsonDecode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(d['chests'] as List);
  }

  Future<List<Map<String, dynamic>>> loadStories() async {
    final raw = await rootBundle.loadString('assets/data/stories.json');
    return List<Map<String, dynamic>>.from(jsonDecode(raw)['stories'] as List);
  }

  Future<Map<String, dynamic>?> loadStory(String id) async {
    final all = await loadStories();
    try {
      return all.firstWhere((s) => s['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadBosses() async {
    final raw = await rootBundle.loadString('assets/data/bosses.json');
    return List<Map<String, dynamic>>.from(jsonDecode(raw)['bosses'] as List);
  }

  Future<Map<String, dynamic>?> loadBossForUnit(String unitId) async {
    final all = await loadBosses();
    try {
      return all.firstWhere((b) => b['unitId'] == unitId);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> loadAudioManifest() async {
    final raw = await rootBundle.loadString('assets/data/audio_manifest.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
