import 'dart:math';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';

/// **Placeholder data source.** Two real vendors sit behind this interface
/// eventually — Firebase Phone Auth for FR-1.1 (OTP), and a third-party
/// selfie-liveness provider (Veriff/Yoti/Didit) for FR-1.2 — see
/// REQUIREMENTS.md §7. `AuthRepositoryImpl` and everything above it stays
/// unchanged when this is swapped for the real integrations, since both
/// implement the same interface.
abstract interface class AuthRemoteDataSource {
  Future<void> checkInviteCode(String code);
  Future<void> requestOtp(String phone);
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    required AccountType accountType,
  });
  Future<AuthUser> submitSelfieVerification(AuthUser user);

  /// See `AuthRepository.getCurrentSession`. The mock has nothing to
  /// restore from — it never persists past a single in-memory session.
  Future<AuthUser?> getCurrentSession();

  /// See `AuthRepository.logOut`.
  Future<void> logOut();
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  /// The one code that "exists" in this mock — real invite codes will live
  /// in Firestore, issued to the first 500 waitlist sign-ups per FR-1.3.
  static const _validInviteCode = 'NASIP2026';

  /// Mock OTP is always this — a real integration never echoes the code
  /// back to the client like this.
  static const _mockOtp = '123456';

  @override
  Future<void> checkInviteCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code.trim().toUpperCase() != _validInviteCode) {
      throw const ServerException('Bu davetiye kodu tanınmıyor.');
    }
  }

  @override
  Future<void> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (phone.trim().length < 10) {
      throw const ServerException('Geçerli bir telefon numarası gir.');
    }
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    required AccountType accountType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code.trim() != _mockOtp) {
      throw const ServerException('Kod hatalı. Tekrar dener misin?');
    }
    return AuthUser(id: _fakeId(), phone: phone, accountType: accountType);
  }

  @override
  Future<AuthUser?> getCurrentSession() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Future<AuthUser> submitSelfieVerification(AuthUser user) async {
    // Real flow: hand off to the vendor SDK, receive a webhook/callback
    // with `verified: true/false` — never a raw image — and store only
    // that boolean + a timestamp (FR-7.2).
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return user.copyWith(verifiedAt: DateTime.now());
  }

  String _fakeId() => 'user_${Random().nextInt(999999)}';
}
