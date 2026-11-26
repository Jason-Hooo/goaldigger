import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/main.dart' as app;
import 'package:goaldigger_app/ui/auth/view_models/auth_view_model.dart';
import 'package:goaldigger_app/ui/auth/views/auth_screen.dart';
import 'package:goaldigger_app/ui/session/session_view_model.dart';
import 'package:provider/provider.dart';

import '../helpers/fakes.dart';

void main() {
  late SessionViewModel session;

  Widget harness() {
    session = SessionViewModel();
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        authRepository: FakeAuthRepository(),
        session: session,
      ),
      child: const MaterialApp(home: AuthScreen()),
    );
  }

  testWidgets('shows inline validation errors from the view model',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '登入'));
    await tester.pump();

    expect(find.text('請輸入有效的 Email'), findsOneWidget);
    expect(find.text('密碼至少 6 碼'), findsOneWidget);
    expect(session.isAuthenticated, isFalse);
  });

  testWidgets('valid credentials sign the session in', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, '登入'));
    await tester.pumpAndSettle();

    expect(session.isAuthenticated, isTrue);
  });

  testWidgets('switches to register mode', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('立即註冊'));
    await tester.pumpAndSettle();

    expect(find.text('Email 註冊'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });

  test('app entry point compiles', () {
    expect(app.main, isA<Function>());
  });
}
