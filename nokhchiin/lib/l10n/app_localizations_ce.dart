// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chechen (`ce`).
class AppLocalizationsCe extends AppLocalizations {
  AppLocalizationsCe([String locale = 'ce']) : super(locale);

  @override
  String get appTitle => 'Нохчийн';

  @override
  String get appTagline => 'Чеченский меттиг лахара некъ';

  @override
  String get kidsModeTitle => 'Беран режим';

  @override
  String get kidsModeSubtitle => 'Ловзар, истореш, йоккха кнопкаш';

  @override
  String get adultModeTitle => 'Хьалха режим';

  @override
  String get adultModeSubtitle => 'Карточкаш, грамматика, статистика';

  @override
  String get agePickerTitle => 'Маха ю?';

  @override
  String get age3to6 => '3–6 шо';

  @override
  String get age6to9 => '6–9 шо';

  @override
  String get age9to12 => '9–12 шо';

  @override
  String get dictionaryTitle => 'Дош';

  @override
  String get dictionarySearchHint => 'Лахар: нохчийн йа русский';

  @override
  String dictionaryMeta(int count) {
    return '$count деш · Мациев + Алироев + дешар';
  }

  @override
  String get verifiedLabel => '✓ хьаьжина';

  @override
  String quizTitle(int score) {
    return 'Викторина · ★ $score';
  }

  @override
  String get notEnoughWords => 'Дешаш йоцуш';

  @override
  String get quizTapHint => 'Кхетаме берг тайп';

  @override
  String get paywallTitle => 'Нохчийн Premium';

  @override
  String get paywallHeadline => 'Маьрша некъ';

  @override
  String get paywallSubtitle => 'ЧкъоьгӀа дешарш, повторенеш, дедаш статистика';

  @override
  String paywallTrialTitle(int days) {
    return '$days де пробный';
  }

  @override
  String get paywallTrialSubtitle => 'тӀаьхьа подписка · хӀан-хӀа а дӀаделахьа';

  @override
  String get paywallStartTrial => 'Пробный дӀадолу';

  @override
  String get paywallBuyPremium => 'Premium схьаэцар';

  @override
  String get paywallRestore => 'Схьаэца покупкаш';

  @override
  String get paywallLegal => 'Кхин дӀа а, шарт а политика а йо';

  @override
  String get compareFree => 'Free';

  @override
  String get comparePremium => 'Premium';

  @override
  String get compareRowUnits => 'Хьалхара 3 юнит';

  @override
  String get compareRowPath => 'Маьрша некъ';

  @override
  String get compareRowSrs => 'SRS чӀогӀа лимит';

  @override
  String get compareRowParent => 'Дедаш статистика';

  @override
  String get compareRowOffline => 'Офлайн пакаш';

  @override
  String get loading => 'Чуйолуш…';

  @override
  String get retry => 'Юха лаха';
}
