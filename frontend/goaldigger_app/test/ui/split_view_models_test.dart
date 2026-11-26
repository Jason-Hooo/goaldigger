import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/core/result/result.dart';
import 'package:goaldigger_app/data/models/split.dart';
import 'package:goaldigger_app/data/services/data_change_notifier.dart';
import 'package:goaldigger_app/ui/split/view_models/group_detail_view_model.dart';
import 'package:goaldigger_app/ui/split/view_models/group_expense_editor_view_model.dart';
import 'package:goaldigger_app/ui/split/view_models/split_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  const trip = GroupSummary(groupId: 1, groupName: 'Trip', invitationCode: 'X');
  const members = [
    GroupMember(userId: 1, userName: 'Me'),
    GroupMember(userId: 2, userName: 'Ann'),
  ];

  SplitExpense expense(int id, {required int payer, String? status}) =>
      SplitExpense(
        consumptionId: id,
        groupId: 1,
        groupName: 'Trip',
        name: 'E$id',
        amount: 100,
        createdAt: DateTime(2026),
        participants: [
          SplitParticipant(
            userId: 1,
            userName: 'Me',
            sharedAmount: 50,
            isPayer: payer == 1,
            status: payer == 1 ? null : status,
          ),
          SplitParticipant(
            userId: 2,
            userName: 'Ann',
            sharedAmount: 50,
            isPayer: payer == 2,
            status: payer == 2 ? null : status,
          ),
        ],
      );

  late FakeSplitRepository repository;

  setUp(() {
    repository = FakeSplitRepository()
      ..members = members
      ..groups = const [
        trip,
        GroupSummary(groupId: 2, groupName: 'Trip', invitationCode: 'Y'),
      ]
      ..expenses = [
        expense(1, payer: 1, status: 'pending'),
        expense(2, payer: 2, status: 'pending'),
        expense(3, payer: 2, status: 'paid'),
      ];
  });

  group('SplitViewModel', () {
    test('aggregates payable / receivable totals', () async {
      final viewModel = SplitViewModel(
        userId: 1,
        splitRepository: repository,
        dataChanges: DataChangeNotifier(),
      );
      await viewModel.load();

      expect(viewModel.receivableTotal, 50);
      expect(viewModel.payableTotal, 50);
      expect(viewModel.groupCount, 1, reason: 'counts unique group names');
    });

    test('createGroup prepends the new group', () async {
      final viewModel = SplitViewModel(
        userId: 1,
        splitRepository: repository,
        dataChanges: DataChangeNotifier(),
      );
      await viewModel.load();

      final result = await viewModel.createGroup('New');

      expect(result, isA<Success<GroupSummary>>());
      expect(viewModel.groups.first.groupName, 'New');
    });
  });

  group('GroupDetailViewModel', () {
    late GroupDetailViewModel viewModel;

    setUp(() {
      repository.expenses = [
        ...repository.expenses,
        SplitExpense(
          consumptionId: 9,
          groupId: 99,
          groupName: 'Other',
          name: 'x',
          amount: 1,
          createdAt: DateTime(2026),
          participants: const [],
        ),
      ];
      viewModel = GroupDetailViewModel(
        userId: 1,
        group: trip,
        splitRepository: repository,
        realtime: FakeRealtimeService(),
      );
    });

    test('only shows expenses of this group', () async {
      await viewModel.load();
      expect(viewModel.expenses.map((e) => e.consumptionId), [1, 2, 3]);
    });

    test('confirmRepayment marks participant paid', () async {
      await viewModel.load();

      await viewModel.confirmRepayment(
        viewModel.expenses.first,
        viewModel.expenses.first.participants[1],
      );

      expect(repository.statusUpdates.single.status, 'paid');
      expect(viewModel.expenseById(1)!.participants[1].isPaid, isTrue);
    });

    test('failed delete restores the expense', () async {
      await viewModel.load();
      repository.shouldFail = true;

      final result = await viewModel.deleteExpense(viewModel.expenses.first);

      expect(result, isA<Failure<void>>());
      expect(viewModel.expenses, hasLength(3));
    });

    test('applySavedExpense shows the new expense with member names', () async {
      await viewModel.load();

      viewModel.applySavedExpense(
        const SplitExpenseRequest(
          groupId: 1,
          name: 'Taxi',
          amount: 20,
          payerId: 1,
          shares: [
            SplitShare(userId: 1, sharedAmount: 10),
            SplitShare(userId: 2, sharedAmount: 10),
          ],
        ),
      );

      final optimistic = viewModel.expenses.first;
      expect(optimistic.name, 'Taxi');
      expect(optimistic.participants.map((p) => p.userName), ['Me', 'Ann']);
      expect(optimistic.payer?.userId, 1);
    });
  });

  group('GroupExpenseEditorViewModel', () {
    GroupExpenseEditorViewModel editor() => GroupExpenseEditorViewModel(
      userId: 1,
      group: trip,
      splitRepository: repository,
      expenseTypeRepository: FakeExpenseTypeRepository(),
    )..init();

    test('loads members and only predefined expense categories', () async {
      final viewModel = editor();
      await pump();

      expect(viewModel.members, members);
      expect(viewModel.expenseTypes.map((t) => t.name), ['餐飲']);
      expect(viewModel.equalShare(100), 50);
    });

    test('rejects shares that do not add up to the total', () async {
      final viewModel = editor();
      await pump();

      final result = await viewModel.submit(
        name: 'Dinner',
        amount: 100,
        shares: {1: 30, 2: 30},
      );

      expect(result, isA<Failure<SplitExpenseRequest>>());
      expect(viewModel.validationError, isNotNull);
      expect(repository.saved, isEmpty);
    });

    test('submits a request with the current user as payer', () async {
      final viewModel = editor();
      await pump();

      final result = await viewModel.submit(
        name: 'Dinner',
        amount: 100,
        shares: {1: 50, 2: 50},
      );

      final request = (result as Success<SplitExpenseRequest>).value;
      expect(request.payerId, 1);
      expect(request.consumptionId, isNull);
      expect(request.shares.map((s) => s.sharedAmount), [50, 50]);
      expect(repository.saved.single, same(request));
    });
  });
}
