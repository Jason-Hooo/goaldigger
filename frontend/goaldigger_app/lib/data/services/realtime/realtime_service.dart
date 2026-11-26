import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handle returned by [RealtimeService.watchTables]; cancel it on dispose.
abstract interface class RealtimeSubscription {
  Future<void> cancel();
}

/// Notifies listeners when rows in the watched database tables change.
abstract interface class RealtimeService {
  RealtimeSubscription watchTables({
    required String channelName,
    required List<String> tables,
    required VoidCallback onChange,
  });
}

/// [RealtimeService] backed by Supabase Postgres change streams.
///
/// Bursts of change events are debounced so that a multi-row write triggers
/// a single refresh.
class SupabaseRealtimeService implements RealtimeService {
  SupabaseRealtimeService(
    this._client, {
    this.debounce = const Duration(milliseconds: 250),
  });

  final SupabaseClient _client;
  final Duration debounce;

  @override
  RealtimeSubscription watchTables({
    required String channelName,
    required List<String> tables,
    required VoidCallback onChange,
  }) {
    final subscription = _SupabaseSubscription(_client, debounce, onChange);
    final channel = _client.channel(channelName);
    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => subscription.schedule(),
      );
    }
    subscription.channel = channel..subscribe();
    return subscription;
  }
}

class _SupabaseSubscription implements RealtimeSubscription {
  _SupabaseSubscription(this._client, this._debounce, this._onChange);

  final SupabaseClient _client;
  final Duration _debounce;
  final VoidCallback _onChange;
  RealtimeChannel? channel;
  Timer? _timer;
  bool _cancelled = false;

  void schedule() {
    if (_cancelled) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      if (!_cancelled) {
        _onChange();
      }
    });
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _timer?.cancel();
    final channel = this.channel;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }
}
