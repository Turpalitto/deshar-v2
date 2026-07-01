import '../domain/entities/culture_capsule.dart';

/// Заглушки для разработки — замените на выверенный контент.
abstract final class CultureCapsuleSamples {
  static const adatAfterFamily = CultureCapsule(
    id: 'capsule_adat_family',
    relatedUnitId: 'family',
    title: 'Адат и гость',
    body:
        'В традиционной культуре уважение к старшим и гостю часто выражается через простые бытовые жесты: уступить место, спокойно выслушать, не перебивать.\n\n'
        'Когда вы учите слова о семье и доме, полезно помнить: вежливое обращение к родственникам — не «формальность», а часть повседневной этики.',
    // imagePath: 'assets/images/culture/adat_guest.png',
  );

  static const teipRoots = CultureCapsule(
    id: 'capsule_teip_roots',
    relatedUnitId: 'home',
    title: 'Тейп: корни и окружение',
    body:
        'Тейп — это не только родственники по крови, но и люди, с которыми связывает общая история, помощь и ответственность друг перед другом.\n\n'
        'В языке много слов о доме и близких: они помогают говорить не только о вещах, но и о связях между людьми.',
  );

  static const hospitality = CultureCapsule(
    id: 'capsule_hospitality',
    relatedUnitId: 'food',
    title: 'Гостеприимство за столом',
    body:
        'Пригласить к столу и предложить еду — один из самых понятных знаков уважения. Отказ может звучать резко, если сказать его без пояснения.\n\n'
        'Нейтральная формула: поблагодарить, коротко объяснить причину и показать, что вы цените заботу собеседника.',
    imagePath: null,
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
