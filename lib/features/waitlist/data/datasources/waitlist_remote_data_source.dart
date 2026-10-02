import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/error_log.dart';
import '../../../../core/error/exceptions.dart';
import '../models/waitlist_entry_model.dart';

abstract interface class WaitlistRemoteDataSource {
  Future<void> submit(WaitlistEntryModel entry);
}

/// FR-1.3 on real Firestore: one `waitlist/{autoId}` doc per sign-up.
/// The visitor isn't signed in yet, so `firestore.rules` lets anyone
/// *create* a (validated) entry and nobody read, edit or delete one -
/// entries are reviewed in the Firebase Console / via the Admin SDK.
/// Duplicates are allowed on purpose (a repeat submission isn't an error
/// worth surfacing to the visitor); dedupe when issuing invites.
class FirestoreWaitlistRemoteDataSource implements WaitlistRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<void> submit(WaitlistEntryModel entry) async {
    if (entry.name.trim().isEmpty || entry.contact.trim().isEmpty) {
      throw const ServerException('Ad ve e-posta/telefon zorunludur.');
    }
    try {
      await _db.collection('waitlist').add(entry.toFirestore());
    } on FirebaseException catch (e) {
      logFailure('waitlist', e);
      throw const ServerException('Kayıt gönderilemedi.');
    }
  }
}
