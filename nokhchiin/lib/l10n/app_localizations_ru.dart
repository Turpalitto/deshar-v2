// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Нохчийн';

  @override
  String get appTagline => 'Лучший путь к чеченскому языку';

  @override
  String get kidsModeTitle => 'Детский режим';

  @override
  String get kidsModeSubtitle => 'Игра, истории, большие кнопки';

  @override
  String get adultModeTitle => 'Взрослый режим';

  @override
  String get adultModeSubtitle => 'Карточки, грамматика, статистика';

  @override
  String get agePickerTitle => 'Сколько лет?';

  @override
  String get age3to6 => '3–6 лет';

  @override
  String get age6to9 => '6–9 лет';

  @override
  String get age9to12 => '9–12 лет';

  @override
  String get dictionaryTitle => 'Словарь';

  @override
  String get dictionarySearchHint => 'Поиск: чеченский или русский';

  @override
  String dictionaryMeta(int count) {
    return '$count слов · Мациев + Алироев + учебник';
  }

  @override
  String get verifiedLabel => '✓ проверено';

  @override
  String quizTitle(int score) {
    return 'Викторина · ★ $score';
  }

  @override
  String get notEnoughWords => 'Недостаточно слов';

  @override
  String get quizTapHint => 'Выберите правильный перевод';

  @override
  String get paywallTitle => 'Нохчийн Premium';

  @override
  String get paywallHeadline => 'Весь путь к чеченскому';

  @override
  String get paywallSubtitle =>
      'Безлимитные уроки, повторения и статистика для родителей';

  @override
  String paywallTrialTitle(int days) {
    return '$days дней бесплатно';
  }

  @override
  String get paywallTrialSubtitle => 'затем подписка · отмена в любой момент';

  @override
  String get paywallStartTrial => 'Начать пробный период';

  @override
  String get paywallBuyPremium => 'Купить Premium';

  @override
  String get paywallRestore => 'Восстановить покупки';

  @override
  String get paywallLegal =>
      'Продолжая, вы соглашаетесь с Условиями и Политикой конфиденциальности';

  @override
  String get compareFree => 'Free';

  @override
  String get comparePremium => 'Premium';

  @override
  String get compareRowUnits => 'Первые 3 юнита';

  @override
  String get compareRowPath => 'Весь путь обучения';

  @override
  String get compareRowSrs => 'SRS без лимита';

  @override
  String get compareRowParent => 'Статистика родителя';

  @override
  String get compareRowOffline => 'Офлайн-паки';

  @override
  String get loading => 'Загрузка…';

  @override
  String get retry => 'Повторить';

  @override
  String get onboardingGreetingChechen => 'Сайн дог ду хьуна';

  @override
  String get onboardingWelcome => 'Рады тебя видеть!';

  @override
  String get onboardingTrackPrompt =>
      'Выбери трек — мы подберём уроки и темп специально для тебя.';

  @override
  String get featureOffline => 'Офлайн';

  @override
  String get featureCulture => 'Культура';

  @override
  String get agePickerSubtitle => 'Подберём темп и контент';

  @override
  String get premiumTooltip => 'Premium';

  @override
  String get giftCapsuleTitle => 'Капсула';

  @override
  String get giftCapsuleSubtitle => 'Гостеприимство';

  @override
  String get giftTitle => 'Подарок';

  @override
  String get giftClaimed => 'Забран';

  @override
  String get giftToday => 'Сегодня';

  @override
  String get dailyGiftRewardTitle => 'Подарок дня!';

  @override
  String get dailyGiftRewardSubtitle => '+15 монет · +20 XP';

  @override
  String get srsStartSession => 'SRS · начать сеанс';

  @override
  String get worldsSectionTitle => 'Миры';

  @override
  String get seeAllArrow => 'Все →';

  @override
  String get worldsLoadError => 'Не удалось загрузить миры';

  @override
  String get quickLinkCollections => 'Коллекции';

  @override
  String get quickLinkStories => 'Истории';

  @override
  String get quickLinkTyping => 'Ввод';

  @override
  String get greetingNight => 'Доброй ночи';

  @override
  String get greetingMorning => 'Доброе утро';

  @override
  String get greetingDay => 'Добрый день';

  @override
  String get greetingEvening => 'Добрый вечер';

  @override
  String get greetingKids => 'Привет, ученик';

  @override
  String levelLabel(int level) {
    return 'Уровень $level';
  }

  @override
  String get streakFreezeTitle => 'Заморозка стрика';

  @override
  String streakFreezeDescription(int count, int max) {
    return 'Сохраняет твой стрик, если пропустишь один день. У тебя: $count из $max.';
  }

  @override
  String get streakFreezeBought => 'Заморозка куплена';

  @override
  String get streakFreezeBuyFailed => 'Не получилось купить';

  @override
  String get streakFreezeMax => 'Уже максимум';

  @override
  String streakFreezeBuyButton(int cost) {
    return 'Купить за $cost монет';
  }

  @override
  String get continueHeroStartTitle => 'Начать путь';

  @override
  String get continueHeroEyebrow => 'ПРОДОЛЖИТЬ УРОК';

  @override
  String continueHeroStep(int step) {
    return 'Урок · $step из 5 шагов';
  }

  @override
  String get continueHeroOpenPath => 'Открой путь обучения';

  @override
  String continueHeroSemanticLabel(String title, int step) {
    return 'Продолжить урок: $title, шаг $step из 5';
  }

  @override
  String get dictionaryEmptyResults => 'Ничего не найдено';

  @override
  String get dictionaryLoadError => 'Ошибка загрузки';

  @override
  String get favoriteTooltip => 'Избранное';

  @override
  String get copyTooltip => 'Копировать';

  @override
  String get copiedSnackbar => 'Скопировано';

  @override
  String get translationLabel => 'Перевод';

  @override
  String get categoryFieldLabel => 'Категория';

  @override
  String get sourceLabel => 'Источник';

  @override
  String get relatedLabel => 'Связанные';

  @override
  String get entryNotFound => 'Запись не найдена';

  @override
  String get back => 'Назад';

  @override
  String get compareRowCulture => 'Все культурные капсулы';
}
