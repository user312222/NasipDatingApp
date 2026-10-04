import '../../../../core/result/result.dart';
import '../entities/account_type.dart';
import '../entities/auth_user.dart';

/// Domain contract for FR-1 (Onboarding & Kimlik Doğrulama). Implemented by
/// [AuthRepositoryImpl] against a mock data source today, and eventually
/// against Firebase Phone Auth (OTP) + a third-party selfie-liveness vendor
/// (Veriff/Yoti/Didit — see REQUIREMENTS.md FR-1.2) without this interface,
/// or anything above it, changing.
abstract interface class AuthRepository {
  /// FR-1.3: gates entry to closed beta. A rejected code means "go join
  /// the waitlist," not a generic error.
  Future<Result<void>> checkInviteCode(String code);

  /// FR-1.1: sends an SMS OTP to [phone].
  Future<Result<void>> requestOtp(String phone);

  /// FR-1.1: verifies the OTP and returns the (not-yet-selfie-verified) user.
  /// [accountType] (FR-8.1, already chosen on `/account-type`) is passed
  /// through so a real backend can persist it against this account right
  /// away — see [getCurrentSession].
  Future<Result<AuthUser>> verifyOtp({
    required String phone,
    required String code,
    required AccountType accountType,
  });

  /// The sign-in door for people who already have an account: verifies
  /// the OTP without any of the registration choices (invite code, account
  /// type, consent - all settled when the account was made). `Ok(null)`
  /// means no account exists for this number; nothing is kept of the
  /// attempt and the caller sends the person to registration instead.
  Future<Result<AuthUser?>> verifySignInOtp({
    required String phone,
    required String code,
  });

  /// FR-1.2: mandatory selfie-liveness check. Returns [user] with
  /// `verifiedAt` set once the vendor confirms — never a raw selfie/ID.
  Future<Result<AuthUser>> submitSelfieVerification(AuthUser user);

  /// Session restore: if this device already has a signed-in, previously
  /// verified account, returns it (so the app can skip straight past the
  /// invite/phone/OTP/selfie steps on a later app open) — `Ok(null)` means
  /// "no active session, show the invite gate normally." A [Result.Err] is
  /// never expected to actually be shown to the user; callers should treat
  /// it the same as `Ok(null)`.
  Future<Result<AuthUser?>> getCurrentSession();

  /// Ends this device's session — after this, [getCurrentSession] must
  /// return `Ok(null)` again. `AccountCubit.logOut` in the account feature
  /// follows this up with `RestartApp.restart` so no in-memory mock state
  /// (matching, messaging, …) survives into the next signed-in session.
  Future<Result<void>> logOut();
}
