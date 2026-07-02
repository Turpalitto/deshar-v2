/// Feature toggles for staged rollout (billing, audio, sync, etc.).
abstract final class FeatureFlags {
  /// Native speaker audio + TTS. Disabled until recordings are ready.
  static const bool audioEnabled = false;

  /// Premium / freemium gating. Disabled — all content is free.
  /// Set to `true` when billing is ready for production.
  static const bool premiumEnabled = false;
}
