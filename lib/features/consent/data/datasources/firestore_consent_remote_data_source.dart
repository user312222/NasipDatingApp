import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import 'consent_remote_data_source.dart';

/// KVKK consent record on real Firestore. One doc per user at
/// `consents/{userId}` — `acceptedAt` is the first-ever acceptance time
/// (never overwritten by a later `set(merge: true)` on the same
/// version); `consentVersion`/`lastAcceptedAt` reflect the most recent
/// acceptance, so a future policy update can ask again and tell "never
/// consented" apart from "consented to an older version."
///
/// **This is a draft-stage implementation**, not a compliance system: it
/// does not keep a full history of every version accepted (a real backend
/// should, for KVKK's burden-of-proof requirement), and it doesn't track
/// which specific notices (data processing vs. cross-border transfer)
/// were accepted separately — `ConsentScreen` requires both boxes checked
/// before it lets the user continue at all, so today they're always
/// accepted together.
class FirestoreConsentRemoteDataSource implements ConsentRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<void> recordConsent({
    required String userId,
    required String consentVersion,
  }) async {
    try {
      final doc = _db.collection('consents').doc(userId);
      final existing = await doc.get();
      await doc.set({
        'consentVersion': consentVersion,
        'lastAcceptedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw ServerException('Rıza kaydı tutulamadı (${e.code}).');
    }
  }
}
