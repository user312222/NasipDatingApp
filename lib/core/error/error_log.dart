import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Technical failure details (Firebase error codes, stack of what went
/// wrong) go to the developer console only - the text a user sees comes
/// from a plain Turkish [ServerException] message. Swap the `debugPrint`
/// for a crash-reporting call (Crashlytics/Sentry) before launch.
///
/// [needsSession] is true for everything that runs behind a sign-in, which
/// is nearly all of the app; the few calls made while signed out (invite
/// code, waitlist, sign-in itself) pass false so that a rejection there is
/// always reported.
void logFailure(String scope, Object error, {bool needsSession = true}) {
  if (needsSession && isSessionEndNoise(error, signedIn: _signedIn())) return;
  debugPrint('[$scope] $error');
}

/// Whether [error] is only the session ending: Firestore listeners (tab
/// dots, an open chat, the feed) are still attached at the moment of
/// sign-out or account deletion, and the rules reject each of them a beat
/// before the app restarts. That is the rules doing their job, not a
/// failure - reporting it would bury real errors once crash reporting is
/// connected. A `permission-denied` while signed *in* is still reported.
@visibleForTesting
bool isSessionEndNoise(Object error, {required bool signedIn}) =>
    !signedIn &&
    error is FirebaseException &&
    error.code == 'permission-denied';

bool _signedIn() {
  try {
    return FirebaseAuth.instance.currentUser != null;
  } on FirebaseException {
    // Firebase is not initialised (unit tests): never hide anything.
    return true;
  }
}
