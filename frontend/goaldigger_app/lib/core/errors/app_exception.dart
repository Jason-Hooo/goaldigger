/// Base type for expected, user-presentable failures.
///
/// Anything that is not an [AppException] is treated as unexpected and is
/// mapped to a generic fallback message by [describeError].
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String kDefaultErrorMessage = '資料讀取失敗，請稍後再試。';

/// Converts any thrown object into a message that is safe to show in the UI.
String describeError(Object error, {String fallback = kDefaultErrorMessage}) {
  if (error is AppException) {
    return error.message;
  }
  return fallback;
}
