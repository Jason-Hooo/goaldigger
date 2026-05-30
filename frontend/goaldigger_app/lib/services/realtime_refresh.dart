part of '../main.dart';

mixin RealtimeRefreshMixin<T extends StatefulWidget> on State<T> {
  final List<RealtimeChannel> _realtimeChannels = [];
  Timer? _refreshDebounce;

  void watchTables({
    required String channelName,
    required List<String> tables,
    required Future<void> Function() onChange,
  }) {
    final channel = Supabase.instance.client.channel(channelName);
    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleRefresh(onChange),
      );
    }
    channel.subscribe();
    _realtimeChannels.add(channel);
  }

  void _scheduleRefresh(Future<void> Function() onChange) {
    if (!mounted) {
      return;
    }

    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      unawaited(onChange());
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final client = Supabase.instance.client;
    for (final channel in _realtimeChannels) {
      client.removeChannel(channel);
    }
    _realtimeChannels.clear();
    super.dispose();
  }
}
