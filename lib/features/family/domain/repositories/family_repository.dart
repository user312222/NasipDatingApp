import '../../../../core/result/result.dart';
import '../entities/family_visible_match.dart';
import '../entities/relationship.dart';

abstract interface class FamilyRepository {
  /// FR-8.2/FR-8.3: guardian-side. Fails if [inviteCode] is invalid.
  Future<Result<void>> linkGuardian({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  });

  /// FR-8.5: guardian-side — everything this guardian is allowed to see.
  Future<Result<List<FamilyVisibleMatch>>> getVisibleMatches(
    String guardianUserId,
  );

  /// Guardian-side: the first name of the account this guardian is linked
  /// to, so the home screen can say whose matches these are (and a wrong
  /// code is noticed). Null when that account has no public profile.
  Future<Result<String?>> getLinkedSingleName(String guardianUserId);

  /// FR-8.3: single-side — creates one on first call, returns the same
  /// code on every later call for this user.
  Future<Result<String>> getOrCreateInviteCode(String singleUserId);
}
