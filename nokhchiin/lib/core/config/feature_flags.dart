/// Feature toggles for staged rollout (billing, audio, sync, etc.).
abstract final class FeatureFlags {
  /// Premium / freemium gating. Disabled — all content is free.
  /// Set to `true` when billing is ready for production.
  static const bool premiumEnabled = false;
}
