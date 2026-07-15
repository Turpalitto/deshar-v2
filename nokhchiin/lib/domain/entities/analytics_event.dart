import 'package:equatable/equatable.dart';

/// События воронки paywall и продукта.
enum AnalyticsEventName {
  paywallViewed('paywall_viewed'),
  paywallDismissed('paywall_dismissed'),
  trialStarted('trial_started'),
  purchaseStarted('purchase_started'),
  purchaseCompleted('purchase_completed'),
  purchaseFailed('purchase_failed'),
  restoreTapped('restore_tapped'),
  restoreCompleted('restore_completed');

  const AnalyticsEventName(this.id);
  final String id;
}

class AnalyticsEvent extends Equatable {
  const AnalyticsEvent({
    required this.name,
    required this.timestamp,
    this.properties = const {},
  });

  final AnalyticsEventName name;
  final DateTime timestamp;
  final Map<String, String> properties;

  Map<String, dynamic> toJson() => {
    'name': name.id,
    'timestamp': timestamp.toIso8601String(),
    'properties': properties,
  };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    name: AnalyticsEventName.values.firstWhere(
      (e) => e.id == json['name'],
      orElse: () => AnalyticsEventName.paywallViewed,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    properties: Map<String, String>.from(json['properties'] as Map? ?? {}),
  );

  @override
  List<Object?> get props => [name, timestamp];
}
