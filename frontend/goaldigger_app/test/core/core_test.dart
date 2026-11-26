import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/core/config/app_config.dart';
import 'package:goaldigger_app/core/errors/app_exception.dart';
import 'package:goaldigger_app/core/result/result.dart';
import 'package:goaldigger_app/core/utils/formatters.dart';
import 'package:goaldigger_app/core/utils/parallel.dart';
import 'package:goaldigger_app/core/utils/validators.dart';

void main() {
  group('Formatters', () {
    test('money rounds and groups thousands', () {
      expect(Formatters.money(0), '0');
      expect(Formatters.money(1234567.6), '1,234,568');
    });

    test('amount keeps cents only when non-zero', () {
      expect(Formatters.amount(1234), '1,234');
      expect(Formatters.amount(1234.5), '1,234.50');
    });

    test('editable drops trailing .0', () {
      expect(Formatters.editable(12), '12');
      expect(Formatters.editable(12.5), '12.5');
    });

    test('dates', () {
      final date = DateTime(2026, 5, 9, 13, 45, 12, 999);
      expect(Formatters.date(date), '2026/05/09');
      expect(Formatters.shortDate(date), '2026/5/9');
      expect(Formatters.monthDay(date), '5/9');
      expect(Formatters.yearMonth(date), '2026/05');
      expect(Formatters.dateTime(date), '2026-05-09 13:45:12');
      expect(Formatters.isoDate(date), '2026-05-09');
    });

    test('parseAmount accepts separators and rejects junk', () {
      expect(Formatters.parseAmount(' 1,234.5 '), 1234.5);
      expect(Formatters.parseAmount('abc'), isNull);
      expect(Formatters.parseAmount(null), isNull);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.isValidEmail('a@b.co'), isTrue);
      expect(Validators.isValidEmail('not-an-email'), isFalse);
    });

    test('amount validators', () {
      expect(Validators.positiveAmount('0'), '金額必須大於 0');
      expect(Validators.positiveAmount('x'), '請輸入數字');
      expect(Validators.positiveAmount('5'), isNull);
      expect(Validators.nonNegativeAmount('-1'), '金額不能為負數');
      expect(Validators.nonNegativeAmount('0'), isNull);
      expect(Validators.required('必填')('  '), '必填');
    });
  });

  group('Result.guard', () {
    test('wraps values and maps AppException messages', () async {
      final ok = await guard(() async => 42);
      expect((ok as Success<int>).value, 42);

      final failed = await guard<int>(
        () async => throw const AppException('nope'),
      );
      expect((failed as Failure<int>).message, 'nope');
    });

    test('hides unexpected errors behind the fallback message', () async {
      final failed = await guard<int>(
        () async => throw StateError('internal'),
        fallbackMessage: 'fallback',
      );
      expect((failed as Failure<int>).message, 'fallback');
    });
  });

  test('Parallel.wait2 rethrows the original error', () async {
    await expectLater(
      Parallel.wait2(
        Future.value(1),
        Future<int>.error(const AppException('api said no')),
      ),
      throwsA(isA<AppException>()),
    );
  });

  group('AppConfig', () {
    test('normalises URLs', () {
      final config = AppConfig.fromEnvironment({
        'SUPABASE_URL': ' https://x.supabase.co/rest/v1/ ',
        'SUPABASE_ANON_KEY': 'key',
        'API_BASE_URL': 'http://localhost:8000/',
      });
      expect(config.supabaseUrl, 'https://x.supabase.co');
      expect(config.apiBaseUrl, 'http://localhost:8000');
    });

    test('fails fast on missing keys', () {
      expect(
        () => AppConfig.fromEnvironment({'SUPABASE_URL': 'x'}),
        throwsStateError,
      );
    });
  });
}
