import '../../../../core/result/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  /// Writes the whole profile: the first time at the end of the wizard,
  /// and again on every edit (`ProfileEditCubit`).
  Future<Result<void>> saveProfile(Profile profile);

  /// [userId]'s own profile as stored, or null when the wizard was never
  /// finished. Only the owner can read it - this is the private document,
  /// not the discovery copy other members see.
  Future<Result<Profile?>> getProfile(String userId);

  /// Whether [userId] has already completed FR-2 — used on session
  /// restore (see `AuthCubit.restoreSession`) to send a returning user
  /// straight to `/discover` instead of back through the profile wizard.
  Future<Result<bool>> hasProfile(String userId);
}
