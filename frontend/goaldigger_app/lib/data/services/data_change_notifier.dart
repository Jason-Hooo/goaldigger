import 'package:flutter/foundation.dart';

/// In-app signal that server-side data was mutated by this client.
///
/// Repositories call [notifyDataChanged] after every successful write so that
/// view models on other tabs can refresh silently. Replaces the former global
/// `AppRefreshBus` singleton with an injectable, testable dependency.
class DataChangeNotifier extends ChangeNotifier {
  void notifyDataChanged() => notifyListeners();
}
