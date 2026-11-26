/// Typed wrappers around [Future.wait].
///
/// Unlike the `(a, b).wait` record extension, which throws a
/// `ParallelWaitError`, these rethrow the first underlying error so that
/// backend error messages reach the UI unchanged.
abstract final class Parallel {
  static Future<(A, B)> wait2<A, B>(Future<A> a, Future<B> b) async {
    final results = await Future.wait<Object?>([a, b]);
    return (results[0] as A, results[1] as B);
  }

  static Future<(A, B, C)> wait3<A, B, C>(
    Future<A> a,
    Future<B> b,
    Future<C> c,
  ) async {
    final results = await Future.wait<Object?>([a, b, c]);
    return (results[0] as A, results[1] as B, results[2] as C);
  }
}
