import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/check_invite_code.dart';
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
  }) : _checkInviteCode = checkInviteCode,
       _requestPhoneOtp = requestPhoneOtp,
       _verifyPhoneOtp = verifyPhoneOtp,
       _submitSelfieVerification = submitSelfieVerification,
       super(const AuthInitial());

  final CheckInviteCode _checkInviteCode;
  final RequestPhoneOtp _requestPhoneOtp;
  final VerifyPhoneOtp _verifyPhoneOtp;
  final SubmitSelfieVerification _submitSelfieVerification;

  /// FR-8.1: chosen on `/account-type`, between the invite gate and phone
  /// entry. Kept as plain cubit state (not part of [AuthState]) because
  /// no screen needs to reactively rebuild on it — it's only read once,
  /// when [verifyOtp] stamps it onto the freshly-verified [AuthUser].
  AccountType _accountType = AccountType.single;

  void selectAccountType(AccountType type) {
    _accountType = type;
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

  Future<void> verifyOtp({required String phone, required String code}) async {
    emit(const OtpVerifyInProgress());
    final result = await _verifyPhoneOtp(VerifyPhoneOtpParams(phone: phone, code: code));
    switch (result) {
      case Ok<AuthUser>(:final value):
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
