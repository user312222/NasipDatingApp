part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Session-restore only (see `AuthCubit.restoreSession`) — deliberately
/// separate from [InviteCheckInProgress]/[PhoneVerified]/etc. so the
/// listeners on the OTP/selfie screens (which key off those states) never
/// fire because of it.
final class SessionRestoring extends AuthState {
  const SessionRestoring();
}

/// This device has no signed-in account (or restore failed) — behave
/// exactly like [AuthInitial], just distinguishable in logs/tests.
final class SessionAbsent extends AuthState {
  const SessionAbsent();
}

/// This device already has a signed-in account — [InviteGateScreen]
/// reacts to this by routing straight past invite/phone/OTP (and past
/// selfie too, if [user] is already verified) instead of showing the
/// invite form.
final class SessionActive extends AuthState {
  const SessionActive(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class InviteCheckInProgress extends AuthState {
  const InviteCheckInProgress();
}

final class InviteAccepted extends AuthState {
  const InviteAccepted();
}

/// Invite code was rejected — FR-1.3: send the user to the waitlist,
/// this is not a generic form error.
final class InviteRejected extends AuthState {
  const InviteRejected();
}

final class OtpRequestInProgress extends AuthState {
  const OtpRequestInProgress(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class OtpSent extends AuthState {
  const OtpSent(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class OtpRequestFailed extends AuthState {
  const OtpRequestFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class OtpVerifyInProgress extends AuthState {
  const OtpVerifyInProgress();
}

final class OtpVerifyFailed extends AuthState {
  const OtpVerifyFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class PhoneVerified extends AuthState {
  const PhoneVerified(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class SelfieVerificationInProgress extends AuthState {
  const SelfieVerificationInProgress();
}

final class OnboardingComplete extends AuthState {
  const OnboardingComplete(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class SelfieVerificationFailed extends AuthState {
  const SelfieVerificationFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
