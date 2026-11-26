import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/core/result/result.dart';
import 'package:goaldigger_app/data/models/goal.dart';
import 'package:goaldigger_app/data/models/ledger_record.dart';
import 'package:goaldigger_app/data/services/data_change_notifier.dart';
import 'package:goaldigger_app/ui/ledger/view_models/ledger_entry.dart';
import 'package:goaldigger_app/ui/ledger/view_models/ledger_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeGoalRepository goals;
  late FakeRealtimeService realtime;
  late DataChangeNotifier changes;
  late LedgerViewModel viewModel;

  setUp(() {
    ledger = FakeLedgerRepository([
      LedgerRecord(
        recordId: 1,
        typeId: 1,
        amount: 30,
        createdAt: DateTime(2026, 5, 1),
        description: 'Lunch · with team',
      ),
      LedgerRecord(
        recordId: 2,
        typeId: 2,
        amount: 1000,
        createdAt: DateTime(2026, 5, 2),
        goalId: 7,
      ),
    ]);
    goals = FakeGoalRepository([
      Goal(
        goalId: 7,
        title: 'Done',
        description: '',
        targetAmount: 1,
        deadline: DateTime(2030),
        status: Goal.statusAchieved,
      ),
    ]);
    realtime = FakeRealtimeService();
    changes = DataChangeNotifier();
    viewModel = LedgerViewModel(
      userId: 1,
      ledgerRepository: ledger,
      expenseTypeRepository: FakeExpenseTypeRepository(),
      goalRepository: goals,
      dataChanges: changes,
      realtime: realtime,
    );
  });

  test('maps records to entries with category and income resolution', () async {
    await viewModel.load();

    final lunch = viewModel.entries.first;
    expect(lunch.title, 'Lunch');
    expect(lunch.note, 'with team');
    expect(lunch.subtitle, '餐飲 · with team');
    expect(lunch.isIncome, isFalse);
    expect(lunch.amountLabel, r'-$30');

    final salary = viewModel.entries.last;
    expect(salary.title, '薪資');
    expect(salary.isIncome, isTrue);

    expect(viewModel.incomeTotal, 1000);
    expect(viewModel.expenseTotal, 30);
    expect(viewModel.balance, 970);
  });

  test('blocks deleting entries linked to achieved goals', () async {
    await viewModel.load();

    final result = await viewModel.delete(viewModel.entries.last);

    expect(result, isA<Failure<void>>());
    expect(ledger.deleted, isEmpty);
    expect(viewModel.entries, hasLength(2));
  });

  test('save is optimistic and rolls back on failure', () async {
    await viewModel.load();
    ledger
      ..shouldFail = true
      ..gate = Completer<void>();

    final pending = viewModel.save(
      const LedgerDraft(
        title: 'Coffee',
        note: '',
        amount: 5,
        isIncome: false,
        typeId: 1,
      ),
    );
    expect(viewModel.entries.first.title, 'Coffee');

    ledger.gate!.complete();
    expect(await pending, isA<Failure<void>>());
    expect(viewModel.entries.map((e) => e.title), ['Lunch', '薪資']);
  });

  test('refreshes on realtime events and data changes; cleans up', () async {
    viewModel.init();
    await pump();
    final initialFetches = ledger.fetchCalls;

    realtime.emit('ledger-1');
    await pump();
    changes.notifyDataChanged();
    await pump();
    expect(ledger.fetchCalls, initialFetches + 2);

    viewModel.dispose();
    expect(realtime.cancelled, ['ledger-1']);
    changes.notifyDataChanged();
    await pump();
    expect(ledger.fetchCalls, initialFetches + 2, reason: 'listener removed');
  });
}
