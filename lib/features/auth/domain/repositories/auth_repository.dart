import '../../../../core/result/result.dart';
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
  Future<Result<AuthUser>> verifyOtp({required String phone, required String code});

  /// FR-1.2: mandatory selfie-liveness check. Returns [user] with
  /// `verifiedAt` set once the vendor confirms — never a raw selfie/ID.
  Future<Result<AuthUser>> submitSelfieVerification(AuthUser user);
}
