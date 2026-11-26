import 'package:flutter/foundation.dart';

import '../../../data/services/data_change_notifier.dart';
import '../../../data/services/realtime/realtime_service.dart';
import 'view_model.dart';

/// Re-fetches a view model's data when this client writes data
/// ([DataChangeNotifier]) and/or when the backend tables change
/// ([RealtimeService]). All listeners are released on [dispose].
mixin AutoRefreshMixin on ViewModel {
  DataChangeNotifier? _changes;
  VoidCallback? _changeListener;
  RealtimeSubscription? _realtime;

  @protected
  void listenToDataChanges(DataChangeNotifier changes, VoidCallback onChange) {
    _changes?.removeListener(_changeListener!);
    _changes = changes;
    _changeListener = onChange;
    changes.addListener(onChange);
  }

  @protected
  void watchRealtime(
    RealtimeService realtime, {
    required String channelName,
    required List<String> tables,
    required VoidCallback onChange,
  }) {
    _realtime?.cancel();
    _realtime = realtime.watchTables(
      channelName: channelName,
      tables: tables,
      onChange: () {
        if (!isDisposed) {
          onChange();
        }
      },
    );
  }

  @override
  void dispose() {
    final listener = _changeListener;
    if (listener != null) {
      _changes?.removeListener(listener);
    }
    _realtime?.cancel();
    super.dispose();
  }
}
