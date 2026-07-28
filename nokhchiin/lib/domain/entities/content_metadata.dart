enum FrequencyTier {
  common,
  uncommon,
  rare;

  static FrequencyTier? fromJson(Object? value) {
    if (value is! String) return null;
    for (final tier in values) {
      if (tier.name == value) return tier;
    }
    return null;
  }
}

enum LanguageRegister {
  modern,
  archaic,
  dialect,
  technical;

  static LanguageRegister? fromJson(Object? value) {
    if (value is! String) return null;
    for (final register in values) {
      if (register.name == value) return register;
    }
    return null;
  }
}

enum ReviewStatus {
  draft,
  sourceChecked,
  nativeVerified,
  published;

  static ReviewStatus fromJson(Object? value) {
    return switch (value) {
      'source_checked' => sourceChecked,
      'native_verified' => nativeVerified,
      'published' => published,
      _ => draft,
    };
  }

  String get jsonValue => switch (this) {
    draft => 'draft',
    sourceChecked => 'source_checked',
    nativeVerified => 'native_verified',
    published => 'published',
  };

  String get labelRu => switch (this) {
    draft => 'Черновик',
    sourceChecked => 'Найдено в словарном источнике',
    nativeVerified => 'Проверено носителем',
    published => 'Проверено носителем и редактором',
  };

  bool get canAppearInLearning => this != draft;
  bool get canAppearInDailyContent => this != draft;
}
