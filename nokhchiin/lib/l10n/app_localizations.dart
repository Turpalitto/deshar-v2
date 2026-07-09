import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нохчийн'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In ru, this message translates to:
  /// **'Лучший путь к чеченскому языку'**
  String get appTagline;

  /// No description provided for @kidsModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Детский режим'**
  String get kidsModeTitle;

  /// No description provided for @kidsModeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Игра, истории, большие кнопки'**
  String get kidsModeSubtitle;

  /// No description provided for @adultModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Взрослый режим'**
  String get adultModeTitle;

  /// No description provided for @adultModeSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Карточки, грамматика, статистика'**
  String get adultModeSubtitle;

  /// No description provided for @agePickerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сколько лет?'**
  String get agePickerTitle;

  /// No description provided for @age3to6.
  ///
  /// In ru, this message translates to:
  /// **'3–6 лет'**
  String get age3to6;

  /// No description provided for @age6to9.
  ///
  /// In ru, this message translates to:
  /// **'6–9 лет'**
  String get age6to9;

  /// No description provided for @age9to12.
  ///
  /// In ru, this message translates to:
  /// **'9–12 лет'**
  String get age9to12;

  /// No description provided for @dictionaryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Словарь'**
  String get dictionaryTitle;

  /// No description provided for @dictionarySearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск: чеченский или русский'**
  String get dictionarySearchHint;

  /// No description provided for @dictionaryMeta.
  ///
  /// In ru, this message translates to:
  /// **'{count} слов · Мациев + Алироев + учебник'**
  String dictionaryMeta(int count);

  /// No description provided for @verifiedLabel.
  ///
  /// In ru, this message translates to:
  /// **'✓ проверено'**
  String get verifiedLabel;

  /// No description provided for @quizTitle.
  ///
  /// In ru, this message translates to:
  /// **'Викторина · ★ {score}'**
  String quizTitle(int score);

  /// No description provided for @notEnoughWords.
  ///
  /// In ru, this message translates to:
  /// **'Недостаточно слов'**
  String get notEnoughWords;

  /// No description provided for @quizTapHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите правильный перевод'**
  String get quizTapHint;

  /// No description provided for @paywallTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нохчийн Premium'**
  String get paywallTitle;

  /// No description provided for @paywallHeadline.
  ///
  /// In ru, this message translates to:
  /// **'Весь путь к чеченскому'**
  String get paywallHeadline;

  /// No description provided for @paywallSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Безлимитные уроки, повторения и статистика для родителей'**
  String get paywallSubtitle;

  /// No description provided for @paywallTrialTitle.
  ///
  /// In ru, this message translates to:
  /// **'{days} дней бесплатно'**
  String paywallTrialTitle(int days);

  /// No description provided for @paywallTrialSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'затем подписка · отмена в любой момент'**
  String get paywallTrialSubtitle;

  /// No description provided for @paywallStartTrial.
  ///
  /// In ru, this message translates to:
  /// **'Начать пробный период'**
  String get paywallStartTrial;

  /// No description provided for @paywallBuyPremium.
  ///
  /// In ru, this message translates to:
  /// **'Купить Premium'**
  String get paywallBuyPremium;

  /// No description provided for @paywallRestore.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить покупки'**
  String get paywallRestore;

  /// No description provided for @paywallLegal.
  ///
  /// In ru, this message translates to:
  /// **'Продолжая, вы соглашаетесь с Условиями и Политикой конфиденциальности'**
  String get paywallLegal;

  /// No description provided for @compareFree.
  ///
  /// In ru, this message translates to:
  /// **'Free'**
  String get compareFree;

  /// No description provided for @comparePremium.
  ///
  /// In ru, this message translates to:
  /// **'Premium'**
  String get comparePremium;

  /// No description provided for @compareRowUnits.
  ///
  /// In ru, this message translates to:
  /// **'Первые 3 юнита'**
  String get compareRowUnits;

  /// No description provided for @compareRowPath.
  ///
  /// In ru, this message translates to:
  /// **'Весь путь обучения'**
  String get compareRowPath;

  /// No description provided for @compareRowSrs.
  ///
  /// In ru, this message translates to:
  /// **'SRS без лимита'**
  String get compareRowSrs;

  /// No description provided for @compareRowParent.
  ///
  /// In ru, this message translates to:
  /// **'Статистика родителя'**
  String get compareRowParent;

  /// No description provided for @compareRowOffline.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн-паки'**
  String get compareRowOffline;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @onboardingGreetingChechen.
  ///
  /// In ru, this message translates to:
  /// **'Сайн дог ду хьуна'**
  String get onboardingGreetingChechen;

  /// No description provided for @onboardingWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Рады тебя видеть!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingTrackPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Выбери трек — мы подберём уроки и темп специально для тебя.'**
  String get onboardingTrackPrompt;

  /// No description provided for @featureOffline.
  ///
  /// In ru, this message translates to:
  /// **'Офлайн'**
  String get featureOffline;

  /// No description provided for @featureCulture.
  ///
  /// In ru, this message translates to:
  /// **'Культура'**
  String get featureCulture;

  /// No description provided for @agePickerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Подберём темп и контент'**
  String get agePickerSubtitle;

  /// No description provided for @premiumTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Premium'**
  String get premiumTooltip;

  /// No description provided for @giftCapsuleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Капсула'**
  String get giftCapsuleTitle;

  /// No description provided for @giftCapsuleSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Гостеприимство'**
  String get giftCapsuleSubtitle;

  /// No description provided for @giftTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подарок'**
  String get giftTitle;

  /// No description provided for @giftClaimed.
  ///
  /// In ru, this message translates to:
  /// **'Забран'**
  String get giftClaimed;

  /// No description provided for @giftToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get giftToday;

  /// No description provided for @dailyGiftRewardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подарок дня!'**
  String get dailyGiftRewardTitle;

  /// No description provided for @dailyGiftRewardSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'+15 монет · +20 XP'**
  String get dailyGiftRewardSubtitle;

  /// No description provided for @srsStartSession.
  ///
  /// In ru, this message translates to:
  /// **'SRS · начать сеанс'**
  String get srsStartSession;

  /// No description provided for @worldsSectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Миры'**
  String get worldsSectionTitle;

  /// No description provided for @seeAllArrow.
  ///
  /// In ru, this message translates to:
  /// **'Все →'**
  String get seeAllArrow;

  /// No description provided for @worldsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить миры'**
  String get worldsLoadError;

  /// No description provided for @quickLinkCollections.
  ///
  /// In ru, this message translates to:
  /// **'Коллекции'**
  String get quickLinkCollections;

  /// No description provided for @quickLinkStories.
  ///
  /// In ru, this message translates to:
  /// **'Истории'**
  String get quickLinkStories;

  /// No description provided for @quickLinkTyping.
  ///
  /// In ru, this message translates to:
  /// **'Ввод'**
  String get quickLinkTyping;

  /// No description provided for @greetingNight.
  ///
  /// In ru, this message translates to:
  /// **'Доброй ночи'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In ru, this message translates to:
  /// **'Доброе утро'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In ru, this message translates to:
  /// **'Добрый день'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In ru, this message translates to:
  /// **'Добрый вечер'**
  String get greetingEvening;

  /// No description provided for @greetingKids.
  ///
  /// In ru, this message translates to:
  /// **'Привет, ученик'**
  String get greetingKids;

  /// No description provided for @levelLabel.
  ///
  /// In ru, this message translates to:
  /// **'Уровень {level}'**
  String levelLabel(int level);

  /// No description provided for @streakFreezeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заморозка стрика'**
  String get streakFreezeTitle;

  /// No description provided for @streakFreezeDescription.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняет твой стрик, если пропустишь один день. У тебя: {count} из {max}.'**
  String streakFreezeDescription(int count, int max);

  /// No description provided for @streakFreezeBought.
  ///
  /// In ru, this message translates to:
  /// **'Заморозка куплена'**
  String get streakFreezeBought;

  /// No description provided for @streakFreezeBuyFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось купить'**
  String get streakFreezeBuyFailed;

  /// No description provided for @streakFreezeMax.
  ///
  /// In ru, this message translates to:
  /// **'Уже максимум'**
  String get streakFreezeMax;

  /// No description provided for @streakFreezeBuyButton.
  ///
  /// In ru, this message translates to:
  /// **'Купить за {cost} монет'**
  String streakFreezeBuyButton(int cost);

  /// No description provided for @continueHeroStartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Начать путь'**
  String get continueHeroStartTitle;

  /// No description provided for @continueHeroEyebrow.
  ///
  /// In ru, this message translates to:
  /// **'ПРОДОЛЖИТЬ УРОК'**
  String get continueHeroEyebrow;

  /// No description provided for @continueHeroStep.
  ///
  /// In ru, this message translates to:
  /// **'Урок · {step} из 5 шагов'**
  String continueHeroStep(int step);

  /// No description provided for @continueHeroOpenPath.
  ///
  /// In ru, this message translates to:
  /// **'Открой путь обучения'**
  String get continueHeroOpenPath;

  /// No description provided for @continueHeroSemanticLabel.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить урок: {title}, шаг {step} из 5'**
  String continueHeroSemanticLabel(String title, int step);

  /// No description provided for @dictionaryEmptyResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get dictionaryEmptyResults;

  /// No description provided for @dictionaryLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки'**
  String get dictionaryLoadError;

  /// No description provided for @favoriteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoriteTooltip;

  /// No description provided for @copyTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get copyTooltip;

  /// No description provided for @copiedSnackbar.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get copiedSnackbar;

  /// No description provided for @translationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Перевод'**
  String get translationLabel;

  /// No description provided for @categoryFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get categoryFieldLabel;

  /// No description provided for @sourceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Источник'**
  String get sourceLabel;

  /// No description provided for @relatedLabel.
  ///
  /// In ru, this message translates to:
  /// **'Связанные'**
  String get relatedLabel;

  /// No description provided for @entryNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Запись не найдена'**
  String get entryNotFound;

  /// No description provided for @back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get back;

  /// No description provided for @compareRowCulture.
  ///
  /// In ru, this message translates to:
  /// **'Все культурные капсулы'**
  String get compareRowCulture;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
