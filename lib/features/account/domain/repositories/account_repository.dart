import '../../../../core/result/result.dart';

abstract interface class AccountRepository {
  /// FR-7.1: erases the account and everything tied to it (profile,
  /// photos, matches, conversations, the verification result). A real
  /// backend does the cascade server-side (e.g. a Cloud Function) so it
  /// can't be half-finished by a client dropping offline.
  Future<Result<void>> deleteAccount(String userId);
}
