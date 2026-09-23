import '../../../../core/result/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<void>> saveProfile(Profile profile);

  /// Whether [userId] has already completed FR-2 — used on session
  /// restore (see `AuthCubit.restoreSession`) to send a returning user
  /// straight to `/discover` instead of back through the profile wizard.
  Future<Result<bool>> hasProfile(String userId);
}
