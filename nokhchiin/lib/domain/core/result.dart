/// Result type for datasource/repository operations.
///
/// Аудит §3.5: системный error-handling слой вместо точечных try/catch.
/// Success(data) — операция успешна, data доступна.
/// Failure(error, stackTrace) — операция провалена.
sealed class Result<T> {
  const Result();

  /// `true` если [Success].
  bool get isSuccess => this is Success<T>;

  /// `true` если [Failure].
  bool get isFailure => this is Failure<T>;

  /// Распаковка data или fallback.
  T getOr(T fallback) => switch (this) {
        Success(:final data) => data,
        Failure() => fallback,
      };

  /// Преобразование data.
  Result<R> map<R>(R Function(T) f) => switch (this) {
        Success(:final data) => Success(f(data)),
        Failure(:final error, :final stackTrace) =>
          Failure(error, stackTrace),
      };

  /// Выполнить fn на Success, иначе вернуть fallback.
  R fold<R>({required R Function(T data) onSuccess, required R Function() onFailure}) =>
      switch (this) {
        Success(:final data) => onSuccess(data),
        Failure() => onFailure(),
      };
}

/// Успешный результат.
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Ошибка.
final class Failure<T> extends Result<T> {
  const Failure(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
