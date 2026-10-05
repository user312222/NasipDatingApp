import '../../features/profile/domain/usecases/has_profile.dart';
import '../result/result.dart';

/// Remembers whether the signed-in single user has a profile, so the router
/// can check it on every navigation without a Firestore read each time.
///
/// A "yes" is remembered for good: a profile does not disappear during a
/// session (deleting the account restarts the app and with it this cache).
/// A "no" is remembered too, but trusted only by the wizard's own steps
/// (see [known]): it turns into a "yes" the moment the wizard is finished,
/// so everywhere a profile is required it is read again.
class ProfileStatusCache {
  ProfileStatusCache(this._hasProfile);

  final HasProfile _hasProfile;
  String? _userWithProfile;
  String? _userWithoutProfile;

  bool isKnown(String userId) => _userWithProfile == userId;

  /// What can be said without a read, or null when one is needed.
  ///
  /// [forWizardStep]: a "no" from earlier in the session is good enough to
  /// open a wizard step - walking through the five of them would otherwise
  /// cost a read each. If it has gone stale (the profile was created on
  /// another device meanwhile) the worst that happens is a wizard whose
  /// save `firestore.rules` checks like any other.
  bool? known(String userId, {required bool forWizardStep}) {
    if (isKnown(userId)) return true;
    if (forWizardStep && _userWithoutProfile == userId) return false;
    return null;
  }

  /// True / false as stored, or null when it could not be read - callers
  /// treat that as "unknown" and do not lock anyone out over it.
  Future<bool?> check(String userId) async {
    if (isKnown(userId)) return true;
    final result = await _hasProfile(HasProfileParams(userId));
    switch (result) {
      case Ok<bool>(value: true):
        _userWithProfile = userId;
        _userWithoutProfile = null;
        return true;
      case Ok<bool>():
        _userWithoutProfile = userId;
        return false;
      case Err<bool>():
        return null;
    }
  }
}
