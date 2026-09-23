import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../consent/domain/entities/consent_version.dart';
import '../../../consent/domain/usecases/record_consent.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/check_invite_code.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/request_phone_otp.dart';
import '../../domain/usecases/submit_selfie_verification.dart';
import '../../domain/usecases/verify_phone_otp.dart';

part 'auth_state.dart';

/// Owns the whole FR-1 onboarding flow (one screen per step reads this
/// single cubit — see `core/router/app_router.dart`) so the phone number
/// and the partially-verified [AuthUser] survive navigating between steps
/// without being threaded through route parameters.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required CheckInviteCode checkInviteCode,
    required RequestPhoneOtp requestPhoneOtp,
    required VerifyPhoneOtp verifyPhoneOtp,
    required SubmitSelfieVerification submitSelfieVerification,
    required GetCurrentSession getCurrentSession,
    required RecordConsent recordConsent,
  }) : _checkInviteCode = checkInviteCode,
       _requestPhoneOtp = requestPhoneOtp,
       _verifyPhoneOtp = verifyPhoneOtp,
       _submitSelfieVerification = submitSelfieVerification,
       _getCurrentSession = getCurrentSession,
       _recordConsent = recordConsent,
       super(const AuthInitial());

  final CheckInviteCode _checkInviteCode;
  final RequestPhoneOtp _requestPhoneOtp;
  final VerifyPhoneOtp _verifyPhoneOtp;
  final SubmitSelfieVerification _submitSelfieVerification;
  final GetCurrentSession _getCurrentSession;
  final RecordConsent _recordConsent;

  /// FR-8.1: chosen on `/account-type`, between the invite gate and phone
  /// entry. Kept as plain cubit state (not part of [AuthState]) because
  /// no screen needs to reactively rebuild on it — it's only read once,
  /// when [verifyOtp] stamps it onto the freshly-verified [AuthUser].
  AccountType _accountType = AccountType.single;

  /// The signed-in user, however [state] currently represents them —
  /// freshly finished onboarding ([OnboardingComplete]), mid-flow but
  /// already verified ([SessionActive], from [restoreSession] or a
  /// returning-account OTP), or still mid-flow-unverified
  /// ([PhoneVerified]). Screens that just need "who is this and is it
  /// still safe to act as them" (settings, family linking, submitting a
  /// profile) should read this instead of pattern-matching `state is
  /// OnboardingComplete` directly — that check silently misses every
  /// session-restored user, since restore never emits [OnboardingComplete].
  AuthUser? get currentUser => switch (state) {
    OnboardingComplete(:final user) => user,
    SessionActive(:final user) => user,
    PhoneVerified(:final user) => user,
    _ => null,
  };

  void selectAccountType(AccountType type) {
    _accountType = type;
  }

  /// KVKK consent, accepted on `/consent` (between `/account-type` and
  /// `/phone`) — see [ConsentScreen]. Kept as plain cubit state for the
  /// same reason as [_accountType]: read once, when [verifyOtp] persists
  /// it for the freshly-created uid.
  bool _consentAccepted = false;

  void acceptConsent() {
    _consentAccepted = true;
  }

  Future<void> checkInviteCode(String code) async {
    emit(const InviteCheckInProgress());
    final result = await _checkInviteCode(code);
    switch (result) {
      case Ok<void>():
        emit(const InviteAccepted());
      case Err<void>():
        emit(const InviteRejected());
    }
  }

  Future<void> requestOtp(String phone) async {
    emit(OtpRequestInProgress(phone));
    final result = await _requestPhoneOtp(phone);
    switch (result) {
      case Ok<void>():
        emit(OtpSent(phone));
      case Err<void>(:final failure):
        emit(OtpRequestFailed(failure.message));
    }
  }

  /// Called once, right when [InviteGateScreen] first mounts. Restores a
  /// previously-signed-in session so a returning user isn't sent through
  /// invite/phone/OTP/selfie again — see `AuthRepository.getCurrentSession`
  /// and the states' own doc comments.
  Future<void> restoreSession() async {
    emit(const SessionRestoring());
    final result = await _getCurrentSession(const NoParams());
    switch (result) {
      case Ok<AuthUser?>(value: final user?):
        _accountType = user.accountType;
        emit(SessionActive(user));
      case Ok<AuthUser?>():
        emit(const SessionAbsent());
      case Err<AuthUser?>():
        emit(const SessionAbsent());
    }
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    emit(const OtpVerifyInProgress());
    final result = await _verifyPhoneOtp(
      VerifyPhoneOtpParams(phone: phone, code: code, accountType: _accountType),
    );
    switch (result) {
      case Ok<AuthUser>(:final value) when value.verifiedAt != null:
        // This phone number already belongs to a fully-onboarded account
        // — Firebase Phone Auth signs back into that SAME uid rather than
        // creating a new one, and `FirebaseAuthRemoteDataSource` detects
        // this and returns the account's persisted state instead of a
        // fresh one. Whatever was just picked on `/account-type` doesn't
        // apply — this "registration" attempt was actually a login.
        _accountType = value.accountType;
        emit(SessionActive(value));
      case Ok<AuthUser>(:final value):
        // New registration — a returning account never reaches this
        // branch (see the SessionActive case above), so this is the one
        // and only place a fresh consent record gets written. Best
        // effort: the user already gave consent on `/consent` before
        // reaching here, so a write failure shouldn't block onboarding —
        // it's a compliance record, not a permission gate.
        if (_consentAccepted) {
          unawaited(
            _recordConsent(
              RecordConsentParams(
                userId: value.id,
                consentVersion: kConsentVersion,
              ),
            ),
          );
        }
        emit(PhoneVerified(value.copyWith(accountType: _accountType)));
      case Err<AuthUser>(:final failure):
        emit(OtpVerifyFailed(failure.message));
    }
  }

  Future<void> submitSelfieVerification(AuthUser user) async {
    emit(const SelfieVerificationInProgress());
    final result = await _submitSelfieVerification(user);
    switch (result) {
      case Ok<AuthUser>(:final value):
        emit(OnboardingComplete(value));
      case Err<AuthUser>(:final failure):
        emit(SelfieVerificationFailed(failure.message));
    }
  }
}
