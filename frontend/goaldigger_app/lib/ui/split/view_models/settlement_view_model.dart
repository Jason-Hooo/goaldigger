import 'dart:async';

import '../../../data/models/split.dart';
import '../../../data/repositories/split/split_repository.dart';
import '../../core/view_models/view_model.dart';

/// Suggested transfers that settle a group's balances.
class SettlementViewModel extends ViewModel with LoadStateMixin {
  SettlementViewModel({
    required this.groupId,
    required SplitRepository splitRepository,
  }) : _splitRepository = splitRepository;

  final int groupId;
  final SplitRepository _splitRepository;

  List<Settlement> _settlements = const [];

  List<Settlement> get settlements => _settlements;

  void init() => unawaited(load());

  Future<void> load() {
    return runLoad<List<Settlement>>(
      () => _splitRepository.fetchSettlements(groupId),
      (settlements) => _settlements = settlements,
    );
  }
}
