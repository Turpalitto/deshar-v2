import '../domain/entities/culture_capsule.dart';

/// Заглушки для разработки — замените на выверенный контент.
///
/// relatedUnitId указывает на greetings/adjectives/verbs — единственные три
/// юнита, реально включённые в learning_path.json на момент правки (аудит
/// §7: colors/animals/home/family/food/numbers/body/nature отключены из-за
/// неверных категорий словаря). Раньше капсулы были привязаны к family/home/
/// food — после отключения этих юнитов капсулы стали недостижимы из обычного
/// флоу обучения (доступны только через dev-превью).
abstract final class CultureCapsuleSamples {
  static const adatAfterFamily = CultureCapsule(
    id: 'capsule_adat_family',
    relatedUnitId: 'greetings',
    title: 'Адат и гость',
    body:
        'В традиционной культуре уважение к старшим и гостю часто выражается через простые бытовые жесты: уступить место, спокойно выслушать, не перебивать.\n\n'
        'Когда вы учите слова о семье и доме, полезно помнить: вежливое обращение к родственникам — не «формальность», а часть повседневной этики.',
    // imagePath: 'assets/images/culture/adat_guest.png',
  );

  static const teipRoots = CultureCapsule(
    id: 'capsule_teip_roots',
    relatedUnitId: 'adjectives',
    title: 'Тейп: корни и окружение',
    body:
        'Тейп — это не только родственники по крови, но и люди, с которыми связывает общая история, помощь и ответственность друг перед другом.\n\n'
        'В языке много слов о доме и близких: они помогают говорить не только о вещах, но и о связях между людьми.',
  );

  static const hospitality = CultureCapsule(
    id: 'capsule_hospitality',
    relatedUnitId: 'verbs',
    title: 'Гостеприимство — больше чем традиция',
    body:
        'В чеченской культуре гость — священен. Хозяин обязан принять любого путника, накормить и защитить — даже врага. Это не просто вежливость, это хьост — честь дома.\n\n'
        'Стол накрывают быстро и щедро. Лучшее место, лучший кусок — гостю. Говорят: «Гость — посланник Бога». Отказать значит нанести обиду, которую помнят годами.',
    imagePath: 'assets/images/brand/culture_hospitality.png',
  );

  static List<CultureCapsule> get all => [
        adatAfterFamily,
        teipRoots,
        hospitality,
      ];

  static CultureCapsule? forUnit(String unitId) {
    for (final c in all) {
      if (c.relatedUnitId == unitId) return c;
    }
    return null;
  }
}
