import '../errors/app_exception.dart';

/// Outcome of a view model command.
///
/// Views pattern-match on [Success] / [Failure] to decide which feedback to
/// show, keeping `BuildContext` and UI copy out of the view models.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(String message, [Object? error]) = Failure<T>;

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, [this.error]);

  final String message;
  final Object? error;
}

/// Runs [action] and captures any thrown error as a [Failure].
Future<Result<T>> guard<T>(
  Future<T> Function() action, {
  String fallbackMessage = kDefaultErrorMessage,
}) async {
  try {
    return Result.success(await action());
  } catch (error) {
    return Result.failure(
      describeError(error, fallback: fallbackMessage),
      error,
    );
  }
}
