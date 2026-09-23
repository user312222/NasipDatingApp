import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../models/profile_model.dart';
import 'profile_remote_data_source.dart';

/// FR-2 on real Firestore: one private document per user at
/// `profiles/{userId}` plus a minimal discovery copy at
/// `publicProfiles/{userId}`.
/// `photoRefs` are still placeholder filenames — photo upload needs Cloud
/// Storage (Blaze plan) and is wired separately. The rules in
/// `firestore.rules` are the authority on who may read/write this doc;
/// the checks here only give friendlier error messages.
class FirestoreProfileRemoteDataSource implements ProfileRemoteDataSource {
  // Resolved lazily so building the DI graph never touches Firebase.
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<void> save(ProfileModel profile) async {
    if (profile.photoRefs.isEmpty || profile.photoRefs.length > 6) {
      throw const ServerException('1 ile 6 arası fotoğraf gerekiyor.');
    }
    if (profile.age < 18) {
      throw const ServerException('18 yaşından küçükler kayıt olamaz.');
    }
    try {
      final birthDate = Timestamp.fromDate(profile.birthDate);
      final updatedAt = FieldValue.serverTimestamp();
      final batch = _db.batch();
      // Private document: everything, readable only by the owner. The
      // Timestamp (not the ISO string in toJson) lets rules enforce 18+.
      batch.set(_db.collection('profiles').doc(profile.userId), {
        ...profile.toJson(),
        'birthDate': birthDate,
        'updatedAt': updatedAt,
      });
      // Discovery copy: ONLY what other users may see. Sensitive fields
      // (madhhab, religiousPracticeNote, education, photoRefs, family
      // opt-in) deliberately never go here — Firestore rules can't hide
      // single fields, so the split is by document. Once on Blaze, a Cloud
      // Function should derive this from the private document instead.
      batch.set(_db.collection('publicProfiles').doc(profile.userId), {
        'userId': profile.userId,
        'name': profile.name,
        'birthDate': birthDate,
        'city': profile.city,
        'intent': profile.intent.name,
        if (profile.occupation != null) 'occupation': profile.occupation,
        'updatedAt': updatedAt,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Profil kaydedilemedi: izin yok.'
            : 'Profil kaydedilemedi (${e.code}).',
      );
    }
  }

  @override
  Future<bool> hasProfile(String userId) async {
    try {
      final doc = await _db.collection('profiles').doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw ServerException('Profil kontrol edilemedi (${e.code}).');
    }
  }
}
