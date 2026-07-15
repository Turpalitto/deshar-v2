import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/analytics_event.dart';

/// Локальная аналитика (воронка paywall) + debug-лог. Готова к Firebase/Amplitude.
class AnalyticsService {
  AnalyticsService();

  static const _boxName = 'analytics_v1';
  static const _maxEvents = 500;

  Future<Box<Map>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<void> track(
    AnalyticsEventName name, {
    Map<String, String> properties = const {},
  }) async {
    final event = AnalyticsEvent(
      name: name,
      timestamp: DateTime.now(),
      properties: properties,
    );
    if (kDebugMode) {
      debugPrint('[Analytics] ${event.name.id} ${event.properties}');
    }
    final box = await _box();
    final key = '${event.timestamp.microsecondsSinceEpoch}';
    await box.put(key, event.toJson());
    await _trim(box);
  }

  Future<void> _trim(Box<Map> box) async {
    if (box.length <= _maxEvents) return;
    final keys = box.keys.cast<String>().toList()..sort();
    for (var i = 0; i < keys.length - _maxEvents; i++) {
      await box.delete(keys[i]);
    }
  }

  /// Сводка воронки paywall для отладки / родительского дашборда.
  Future<Map<String, int>> paywallFunnelCounts() async {
    final box = await _box();
    final counts = <String, int>{};
    for (final raw in box.values) {
      final map = Map<String, dynamic>.from(raw);
      final name = map['name'] as String? ?? '';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  Future<List<AnalyticsEvent>> recentEvents({int limit = 50}) async {
    final box = await _box();
    final keys = box.keys.cast<String>().toList()..sort();
    final events = <AnalyticsEvent>[];
    for (final k in keys.reversed.take(limit)) {
      final raw = box.get(k);
      if (raw != null) {
        events.add(AnalyticsEvent.fromJson(Map<String, dynamic>.from(raw)));
      }
    }
    return events;
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (_) => AnalyticsService(),
);
