import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';

/// Base class for every view model.
///
/// Guards against `notifyListeners` after `dispose`, which happens routinely
/// when an async request completes after the user has left the screen.
abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Standard loading / refreshing / error state for screens backed by a
/// remote fetch.
///
/// * First load (or a non-silent reload) shows a blocking spinner.
/// * A silent reload after data exists only flips [isRefreshing].
/// * Responses from superseded requests are discarded.
mixin LoadStateMixin on ViewModel {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  int _generation = 0;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get errorMessage => _errorMessage;

  /// Fetches with [fetch] and, if this is still the latest request, hands the
  /// result to [commit] before notifying listeners.
  @protected
  Future<void> runLoad<T>(
    Future<T> Function() fetch,
    void Function(T data) commit, {
    bool silent = false,
    String fallbackMessage = kDefaultErrorMessage,
  }) async {
    final generation = ++_generation;
    if (!silent || !_hasLoadedOnce) {
      _isLoading = true;
      _errorMessage = null;
    } else {
      _isRefreshing = true;
    }
    notifyListeners();

    try {
      final data = await fetch();
      if (generation != _generation) {
        return;
      }
      commit(data);
      _hasLoadedOnce = true;
    } catch (error) {
      if (generation != _generation) {
        return;
      }
      _errorMessage = describeError(error, fallback: fallbackMessage);
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }
}
