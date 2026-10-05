import '../../features/profile/domain/usecases/has_profile.dart';
import '../result/result.dart';

/// Remembers that the signed-in single user has a profile, so the router
/// can check it on every navigation without a Firestore read each time.
///
/// Only a "yes" is remembered: a profile does not disappear during a
/// session (deleting the account restarts the app and with it this cache),
/// while a "no" turns into a "yes" the moment the wizard is finished.
class ProfileStatusCache {
  ProfileStatusCache(this._hasProfile);

  final HasProfile _hasProfile;
  String? _userWithProfile;

  bool isKnown(String userId) => _userWithProfile == userId;

  /// True / false as stored, or null when it could not be read - callers
  /// treat that as "unknown" and do not lock anyone out over it.
  Future<bool?> check(String userId) async {
    if (isKnown(userId)) return true;
    final result = await _hasProfile(HasProfileParams(userId));
    switch (result) {
      case Ok<bool>(value: true):
        _userWithProfile = userId;
        return true;
      case Ok<bool>():
        return false;
      case Err<bool>():
        return null;
    }
  }
}
