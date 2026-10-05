import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/auth/domain/entities/account_type.dart';
import 'package:binasip/features/auth/domain/entities/auth_user.dart';
import 'package:binasip/features/auth/domain/usecases/check_invite_code.dart';
import 'package:binasip/features/auth/domain/usecases/get_current_session.dart';
import 'package:binasip/features/auth/domain/usecases/request_phone_otp.dart';
import 'package:binasip/features/auth/domain/usecases/submit_selfie_verification.dart';
import 'package:binasip/features/auth/domain/usecases/verify_phone_otp.dart';
import 'package:binasip/features/auth/domain/usecases/verify_sign_in_otp.dart';
import 'package:binasip/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:binasip/features/consent/domain/usecases/record_consent.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late FakeConsentRepository consent;
  late AuthCubit cubit;

  final existing = AuthUser(
    id: 'existing_user',
    phone: '5550000000',
    accountType: AccountType.guardian,
    verifiedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repo = FakeAuthRepository();
    consent = FakeConsentRepository();
    cubit = AuthCubit(
      checkInviteCode: CheckInviteCode(repo),
      requestPhoneOtp: RequestPhoneOtp(repo),
      verifyPhoneOtp: VerifyPhoneOtp(repo),
      verifySignInOtp: VerifySignInOtp(repo),
      submitSelfieVerification: SubmitSelfieVerification(repo),
      getCurrentSession: GetCurrentSession(repo),
      recordConsent: RecordConsent(consent),
    );
  });

  group('sign-in door ("Hesabım var")', () {
    test('an existing account goes straight in, as its stored type', () async {
      repo.signInResult = Ok(existing);
      cubit.beginSignIn();

      await cubit.verifyOtp(phone: '5550000000', code: '123456');

      expect(cubit.state, SessionActive(existing));
      expect(cubit.currentUser?.accountType, AccountType.guardian);
      expect(repo.signInCalls, 1);
    });

    test(
      'never runs the registration check or writes a consent record',
      () async {
        repo.signInResult = Ok(existing);
        cubit
          ..acceptConsent()
          ..beginSignIn();

        await cubit.verifyOtp(phone: '5550000000', code: '123456');
        await pumpEventQueue();

        expect(repo.registerCalls, isEmpty);
        expect(consent.recordedFor, isEmpty);
      },
    );

    test('an unknown number is reported, not registered', () async {
      cubit.beginSignIn();

      await cubit.verifyOtp(phone: '5550000009', code: '123456');

      expect(cubit.state, const SignInAccountNotFound());
      expect(repo.registerCalls, isEmpty);
      expect(cubit.currentUser, isNull);
    });

    test(
      'after an unknown number the next attempt is a registration',
      () async {
        cubit.beginSignIn();
        await cubit.verifyOtp(phone: '5550000009', code: '123456');
        expect(cubit.isSigningIn, isFalse);

        await cubit.verifyOtp(phone: '5550000009', code: '123456');

        expect(repo.registerCalls, hasLength(1));
        expect(cubit.state, isA<PhoneVerified>());
      },
    );

    test('a wrong code is a verify failure', () async {
      repo.signInResult = const Err(ServerFailure('Kod hatalı.'));
      cubit.beginSignIn();

      await cubit.verifyOtp(phone: '5550000000', code: '000000');

      expect(cubit.state, const OtpVerifyFailed('Kod hatalı.'));
      expect(cubit.isSigningIn, isTrue);
    });
  });

  group('registration door (invite code)', () {
    test('an accepted invite code leaves the sign-in door', () async {
      cubit.beginSignIn();

      await cubit.checkInviteCode('NASIP2026');

      expect(cubit.state, const InviteAccepted());
      expect(cubit.isSigningIn, isFalse);
    });

    test('a rejected code changes nothing about the door', () async {
      repo.inviteResult = const Err(
        ServerFailure('Bu davetiye kodu tanınmıyor.'),
      );
      cubit.beginSignIn();

      await cubit.checkInviteCode('YANLIS');

      expect(cubit.state, const InviteRejected());
      expect(cubit.isSigningIn, isTrue);
    });

    test('stores the chosen account type and records the consent', () async {
      await cubit.checkInviteCode('NASIP2026');
      cubit
        ..selectAccountType(AccountType.guardian)
        ..acceptConsent();

      await cubit.verifyOtp(phone: '5550000009', code: '123456');
      await pumpEventQueue();

      expect(repo.registerCalls, [AccountType.guardian]);
      expect(repo.signInCalls, 0);
      expect(consent.recordedFor, ['new_user']);
      expect(
        (cubit.state as PhoneVerified).user.accountType,
        AccountType.guardian,
      );
    });

    test('a number that already has an account is still a login', () async {
      repo.registerResult = Ok(existing);
      await cubit.checkInviteCode('NASIP2026');
      cubit
        ..selectAccountType(AccountType.single)
        ..acceptConsent();

      await cubit.verifyOtp(phone: '5550000000', code: '123456');
      await pumpEventQueue();

      expect(cubit.state, SessionActive(existing));
      expect(consent.recordedFor, isEmpty);
    });
  });

  group('what the router is told', () {
    test('nothing is unlocked at the start', () {
      expect(cubit.inviteAccepted, isFalse);
      expect(cubit.consentAccepted, isFalse);
      expect(cubit.otpRequested, isFalse);
      expect(cubit.isSigningIn, isFalse);
    });

    test('each registration step unlocks the next', () async {
      await cubit.checkInviteCode('NASIP2026');
      expect(cubit.inviteAccepted, isTrue);

      cubit.acceptConsent();
      expect(cubit.consentAccepted, isTrue);

      await cubit.requestOtp('5550000009');
      expect(cubit.otpRequested, isTrue);
    });

    test(
      'a rejected invite code or a failed code request unlocks nothing',
      () async {
        repo
          ..inviteResult = const Err(
            ServerFailure('Bu davetiye kodu tanınmıyor.'),
          )
          ..otpRequestResult = const Err(ServerFailure('Kod gönderilemedi.'));

        await cubit.checkInviteCode('YANLIS');
        await cubit.requestOtp('5550000009');

        expect(cubit.inviteAccepted, isFalse);
        expect(cubit.otpRequested, isFalse);
      },
    );
  });

  group('session restore', () {
    test('an active session is picked up', () async {
      repo.session = Ok(existing);

      await cubit.restoreSession();

      expect(cubit.state, SessionActive(existing));
    });

    test('no session shows the entry screen', () async {
      await cubit.restoreSession();

      expect(cubit.state, const SessionAbsent());
    });
  });
}
