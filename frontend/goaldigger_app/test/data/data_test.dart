import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/data/models/goal.dart';
import 'package:goaldigger_app/data/models/ledger_record.dart';
import 'package:goaldigger_app/data/models/split.dart';
import 'package:goaldigger_app/data/repositories/goal/goal_repository_remote.dart';
import 'package:goaldigger_app/data/repositories/split/split_repository_remote.dart';
import 'package:goaldigger_app/data/services/api/api_client.dart';
import 'package:goaldigger_app/data/services/data_change_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Goal', () {
    final future = DateTime.now().add(const Duration(days: 10));
    final past = DateTime.now().subtract(const Duration(days: 1));

    test('progress is clamped and guards zero target', () {
      final goal = Goal(
        title: 'g',
        description: '',
        targetAmount: 100,
        deadline: future,
        savedAmount: 150,
      );
      expect(goal.progress, 1);
      expect(goal.remainingAmount, -50);
      expect(goal.copyWith(targetAmount: 0).progress, 0);
    });

    test('state rules', () {
      final base = Goal(
        title: 'g',
        description: '',
        targetAmount: 100,
        deadline: future,
        savedAmount: 100,
      );
      expect(base.canAchieve, isTrue);
      expect(base.copyWith(deadline: past).isFailed, isTrue);
      expect(base.copyWith(deadline: past).canAchieve, isFalse);
      final achieved = base.copyWith(status: Goal.statusAchieved);
      expect(achieved.isAchieved, isTrue);
      expect(achieved.canAchieve, isFalse);
      expect(achieved.copyWith(deadline: past).isFailed, isFalse);
    });

    test('fromJson falls back to submitted values', () {
      final fallback = Goal(
        goalId: 7,
        title: 'Camera',
        description: 'desc',
        targetAmount: 500,
        deadline: DateTime(2027, 1, 1),
      );
      final goal = Goal.fromJson({'status': 'active'}, fallback: fallback);
      expect(goal.goalId, 7);
      expect(goal.title, 'Camera');
      expect(goal.deadline, DateTime(2027, 1, 1));
      expect(goal.status, 'active');
    });
  });

  group('LedgerRecord description codec', () {
    LedgerRecord record(String? description) => LedgerRecord(
      recordId: 1,
      typeId: 1,
      amount: 1,
      createdAt: DateTime(2026),
      description: description,
    );

    test('round-trips title and multi-part note', () {
      final encoded = LedgerRecord.encodeDescription(
        title: 'Lunch',
        note: 'with A · and B',
      );
      expect(record(encoded).titleOr('x'), 'Lunch');
      expect(record(encoded).note, 'with A · and B');
    });

    test('falls back when empty', () {
      expect(record(null).titleOr('餐飲'), '餐飲');
      expect(record('Solo').note, '');
      expect(LedgerRecord.encodeDescription(title: 'T', note: ''), 'T');
    });
  });

  group('SplitExpense.balanceFor', () {
    SplitExpense expense(List<SplitParticipant> participants) => SplitExpense(
      consumptionId: 1,
      groupId: 1,
      groupName: 'Trip',
      name: 'Dinner',
      amount: 300,
      createdAt: DateTime(2026),
      participants: participants,
    );

    final participants = [
      const SplitParticipant(
        userId: 1,
        userName: 'Me',
        sharedAmount: 100,
        isPayer: true,
      ),
      const SplitParticipant(
        userId: 2,
        userName: 'A',
        sharedAmount: 100,
        isPayer: false,
        status: 'pending',
      ),
      const SplitParticipant(
        userId: 3,
        userName: 'B',
        sharedAmount: 100,
        isPayer: false,
        status: 'paid',
      ),
    ];

    test('payer is owed only unpaid shares of others', () {
      final balance = expense(participants).balanceFor(1);
      expect(balance.isPayer, isTrue);
      expect(balance.receivable, 100);
      expect(balance.payable, 0);
      expect(balance.isSettled, isFalse);
    });

    test('debtor owes own share until paid', () {
      expect(expense(participants).balanceFor(2).payable, 100);
      expect(expense(participants).balanceFor(3).payable, 0);
      expect(expense(participants).balanceFor(3).isSettled, isTrue);
    });

    test('non-participant owes nothing', () {
      final balance = expense(participants).balanceFor(42);
      expect(balance.payable, 0);
      expect(balance.receivable, 0);
    });
  });

  group('ApiClient', () {
    test('sends JSON and decodes UTF-8 bodies', () async {
      late http.Request captured;
      final client = ApiClient(
        baseUrl: 'http://api.test/',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'name': '晚餐'})),
            200,
          );
        }),
      );

      final body = await client.post('/x', body: {'a': 1}, query: {'q': '1'});
      expect(captured.url.toString(), 'http://api.test/x?q=1');
      expect(captured.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(captured.body), {'a': 1});
      expect(body, {'name': '晚餐'});
    });

    test('maps error detail to ApiException', () async {
      final client = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode({'detail': 'bad'}), 400),
        ),
      );
      await expectLater(
        client.get('/x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'bad')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });

  group('Remote repositories', () {
    test('notify data changes only after successful writes', () async {
      var status = 200;
      final changes = DataChangeNotifier();
      var notified = 0;
      changes.addListener(() => notified++);
      final repo = GoalRepositoryRemote(
        ApiClient(
          baseUrl: 'http://api.test',
          httpClient: MockClient((_) async => http.Response('', status)),
        ),
        changes,
      );

      await repo.deleteGoal(1);
      expect(notified, 1);

      status = 500;
      await expectLater(repo.deleteGoal(1), throwsA(isA<ApiException>()));
      expect(notified, 1);
    });

    test('split repository routes create vs update and parses settlements',
        () async {
      final calls = <String>[];
      final repo = SplitRepositoryRemote(
        ApiClient(
          baseUrl: 'http://api.test',
          httpClient: MockClient((request) async {
            calls.add('${request.method} ${request.url.path}');
            if (request.url.path.startsWith('/splits/settle')) {
              return http.Response(
                jsonEncode({
                  'settlements': [
                    {'from_name': 'A', 'to_name': 'B', 'amount': 50},
                  ],
                }),
                200,
              );
            }
            return http.Response('', 200);
          }),
        ),
        DataChangeNotifier(),
      );

      const request = SplitExpenseRequest(
        groupId: 1,
        name: 'n',
        amount: 1,
        payerId: 1,
        shares: [],
      );
      await repo.saveExpense(request);
      await repo.saveExpense(
        const SplitExpenseRequest(
          consumptionId: 9,
          groupId: 1,
          name: 'n',
          amount: 1,
          payerId: 1,
          shares: [],
        ),
      );
      final settlements = await repo.fetchSettlements(3);

      expect(calls, [
        'POST /splits/expenses/create',
        'PUT /splits/expenses/9',
        'GET /splits/settle/3',
      ]);
      expect(settlements.single.amount, 50);
      expect(settlements.single.fromName, 'A');
    });
  });
}
