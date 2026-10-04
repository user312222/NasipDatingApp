import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/features/auth/domain/usecases/check_invite_code.dart';
import 'package:binasip/features/auth/domain/usecases/get_current_session.dart';
import 'package:binasip/features/auth/domain/usecases/request_phone_otp.dart';
import 'package:binasip/features/auth/domain/usecases/submit_selfie_verification.dart';
import 'package:binasip/features/auth/domain/usecases/verify_phone_otp.dart';
import 'package:binasip/features/auth/domain/usecases/verify_sign_in_otp.dart';
import 'package:binasip/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:binasip/features/auth/presentation/screens/invite_gate_screen.dart';
import 'package:binasip/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:binasip/features/auth/presentation/screens/phone_entry_screen.dart';
import 'package:binasip/features/consent/domain/usecases/record_consent.dart';
import 'package:binasip/theme/app_theme.dart';
import 'package:binasip/theme/wizard_widgets.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthRepository repo;

  Future<void> pumpEntry(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = AuthCubit(
      checkInviteCode: CheckInviteCode(repo),
      requestPhoneOtp: RequestPhoneOtp(repo),
      verifyPhoneOtp: VerifyPhoneOtp(repo),
      verifySignInOtp: VerifySignInOtp(repo),
      submitSelfieVerification: SubmitSelfieVerification(repo),
      getCurrentSession: GetCurrentSession(repo),
      recordConsent: RecordConsent(FakeConsentRepository()),
    );
    addTearDown(cubit.close);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const InviteGateScreen()),
        GoRoute(path: '/phone', builder: (_, _) => const PhoneEntryScreen()),
        GoRoute(path: '/otp', builder: (_, _) => const OtpVerificationScreen()),
        GoRoute(
          path: '/account-type',
          builder: (_, _) => const Scaffold(body: Text('hesap türü adımı')),
        ),
      ],
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> signInWith(WidgetTester tester, String phone) async {
    await tester.tap(find.text('Hesabım var, giriş yap'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), phone);
    await tester.tap(find.text('Kod gönder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = FakeAuthRepository());

  testWidgets('the entry screen offers both doors', (tester) async {
    await pumpEntry(tester);

    expect(find.text('DAVETİYE KODU'), findsOneWidget);
    expect(find.text('Hesabım var, giriş yap'), findsOneWidget);
    expect(find.textContaining('kayıtlı bir hesap bulamadık'), findsNothing);
  });

  testWidgets('the sign-in door goes straight to the phone number', (
    tester,
  ) async {
    await pumpEntry(tester);

    await tester.tap(find.text('Hesabım var, giriş yap'));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
    expect(find.text('TELEFON NUMARASI'), findsOneWidget);
    // Not a registration step: no "3 of 5" progress bar.
    expect(find.byType(WizardProgress), findsNothing);
  });

  testWidgets('the invite door still leads to the registration steps', (
    tester,
  ) async {
    await pumpEntry(tester);

    await tester.enterText(find.byType(TextField), 'NASIP2026');
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();

    expect(find.text('hesap türü adımı'), findsOneWidget);
  });

  testWidgets(
    'an unknown number comes back to the entry screen with a notice',
    (tester) async {
      await pumpEntry(tester);

      await signInWith(tester, '5550000009');

      expect(
        find.textContaining('kayıtlı bir hesap bulamadık'),
        findsOneWidget,
      );
      expect(find.text('DAVETİYE KODU'), findsOneWidget);
      expect(repo.signInCalls, 1);
      expect(repo.registerCalls, isEmpty);
    },
  );

  testWidgets('trying the sign-in door again clears the notice', (
    tester,
  ) async {
    await pumpEntry(tester);
    await signInWith(tester, '5550000009');

    await tester.tap(find.text('Hesabım var, giriş yap'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('kayıtlı bir hesap bulamadık'), findsNothing);
  });
}
