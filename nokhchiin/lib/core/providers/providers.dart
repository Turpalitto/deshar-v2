// Barrel — обратная совместимость сохранена.
// Провайдеры вынесены в отдельные файлы (Фаза 2).
//
// Структура:
//   datasource_providers.dart  — источники данных
//   repository_providers.dart  — репозитории
//   usecase_providers.dart     — use cases
//   user_profile_provider.dart — UserProfileNotifier (AsyncNotifier)
//   billing_providers.dart     — биллинг и подписка
//   content_providers.dart     — словарь, юниты, статистика, контент
export 'datasource_providers.dart';
export 'repository_providers.dart';
export 'usecase_providers.dart';
export 'user_profile_provider.dart';
export 'billing_providers.dart';
export 'content_providers.dart';
export 'dictionary_search_providers.dart';
