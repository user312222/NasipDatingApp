import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import 'account_remote_data_source.dart';

/// FR-7.1 on real Firestore + Firebase Auth, **without Cloud Functions**
/// (Spark plan) — so this is a **best-effort, client-side cascade**, not
/// the atomic server-side delete a real backend should eventually do.
///
/// What this deletes:
/// - `profiles/{uid}`, `publicProfiles/{uid}`, `users/{uid}`
/// - This account's own `familyInviteCodes/{uid}` + its
///   `familyInviteCodeLookup/{code}` entry, and `guardianOf/{uid}` (if it
///   was a guardian account)
/// - Every `familyVisible` doc this account owns (`singleUserId == uid`)
///   and every `matchReads` doc (`userId == uid`, the unread markers)
/// - The Firebase Auth user itself — this is what actually ends the
///   session for good and frees the phone number for a fresh sign-up.
///
/// Deliberately NOT deleted: `consents/{uid}` (the KVKK consent record —
/// see `features/consent`). A consent record is evidence *for* the user
/// (proof they agreed, and when) and is exactly the kind of thing that
/// should outlive the account it was recorded against, at least for a
/// reasonable retention window; deleting it on account deletion would
/// defeat its purpose. This is a judgment call, not a legal one — flag it
/// for the same review as the consent notice text itself.
///
/// What this **cannot** safely delete under the current security rules
/// (a real gap, not an oversight — closing it needs Cloud Functions):
/// `likes`, `likeCounters`, `matches`, chat `messages` — these either
/// have no client delete rule at all, or are jointly owned by the other
/// party in a match and unilaterally deleting them would corrupt *their*
/// data. Screens that render a match/message already fall back to a
/// placeholder when the other side's profile is missing (see
/// `FirestoreMatchingRemoteDataSource._toCandidate` callers), so a
/// deleted account's leftover records degrade gracefully rather than
/// crashing anything.
class FirestoreAccountRemoteDataSource implements AccountRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<void> deleteAccount(String userId) async {
    await _bestEffort(() => _db.collection('profiles').doc(userId).delete());
    await _bestEffort(
      () => _db.collection('publicProfiles').doc(userId).delete(),
    );
    await _bestEffort(() => _db.collection('guardianOf').doc(userId).delete());
    await _bestEffort(() => _deleteInviteCode(userId));
    await _bestEffort(() => _deleteOwnFamilyVisible(userId));
    await _bestEffort(() => _deleteOwnMatchReads(userId));
    // Last: users/{uid} itself, then the Auth account — once the Auth
    // user is gone, this uid can no longer write anything anyway.
    await _bestEffort(() => _db.collection('users').doc(userId).delete());

    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == userId) {
        await current.delete();
      }
    } on FirebaseAuthException catch (e) {
      // `requires-recent-login` is the one realistic failure here (a long
      // idle session) — the Firestore data above is still gone, so this
      // isn't treated as a hard failure. It DOES mean the Auth user (and
      // so the phone number) survives, so at least force this device's
      // session to end with a plain sign-out — otherwise the UI would
      // tell the user "your account is deleted" while they're still
      // signed into it, which is worse than the phone number staying
      // taken until they sign in once more and delete again.
      if (e.code != 'requires-recent-login') {
        throw ServerException('Hesap tam silinemedi (${e.code}).');
      }
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _deleteInviteCode(String userId) async {
    final doc = await _db.collection('familyInviteCodes').doc(userId).get();
    final code = doc.data()?['code'] as String?;
    final batch = _db.batch();
    batch.delete(_db.collection('familyInviteCodes').doc(userId));
    if (code != null) {
      batch.delete(_db.collection('familyInviteCodeLookup').doc(code));
    }
    await batch.commit();
  }

  Future<void> _deleteOwnFamilyVisible(String userId) async {
    final snap = await _db
        .collection('familyVisible')
        .where('singleUserId', isEqualTo: userId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _deleteOwnMatchReads(String userId) async {
    final snap = await _db
        .collection('matchReads')
        .where('userId', isEqualTo: userId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Each cleanup step runs independently — one failing (e.g. a rule
  /// rejecting an already-orphaned doc) shouldn't stop the rest.
  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException {
      // Ignored — see class doc comment on what this can't guarantee.
    }
  }
}
