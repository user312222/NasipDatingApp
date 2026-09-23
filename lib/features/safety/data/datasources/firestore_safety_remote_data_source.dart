import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/report_reason.dart';
import 'safety_remote_data_source.dart';

/// FR-6.1/6.2 on real Firestore, **without Cloud Functions** (Spark plan).
///
/// Collections:
/// - `reports/{id}` — create-only, readable by nobody client-side (not
///   even the reporter); a moderator reviews these via the Admin SDK.
/// - `blockedUsers/{blockerId}_{blockedId}` — one doc per block, listed
///   by [getBlockedIds] for `matching`'s data layer to filter with (same
///   pattern `familyVisible` uses for the family feature).
///
/// FR-6.3 photo moderation has **no real backend yet** — real image
/// analysis (Cloud Vision SafeSearch or similar) needs Cloud Storage +
/// either Cloud Functions or a server call, both gated behind the Blaze
/// plan. [moderatePhoto] keeps the same filename heuristic the mock uses,
/// so the rejection path stays exercisable in the UI until that's wired.
class FirestoreSafetyRemoteDataSource implements SafetyRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ServerException('Oturum bulunamadı. Tekrar giriş yap.');
    }
    return user.uid;
  }

  @override
  Future<void> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      await _db.collection('reports').add({
        'reporterId': _uid,
        'targetUserId': targetUserId,
        'reason': reason.name,
        if (details != null && details.isNotEmpty) 'details': details,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Şikayet gönderilemedi (${e.code}).');
    }
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    try {
      final me = _uid;
      await _db.collection('blockedUsers').doc('${me}_$targetUserId').set({
        'blockerId': me,
        'blockedId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Engellenemedi (${e.code}).');
    }
  }

  @override
  Future<Set<String>> getBlockedIds() async {
    try {
      final snap = await _db
          .collection('blockedUsers')
          .where('blockerId', isEqualTo: _uid)
          .get();
      return snap.docs.map((d) => d.data()['blockedId'] as String).toSet();
    } on FirebaseException catch (e) {
      throw ServerException('Engellenenler yüklenemedi (${e.code}).');
    }
  }

  /// Mock rule kept on purpose — see class doc comment.
  @override
  Future<void> moderatePhoto({
    required String fileName,
    required Uint8List bytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (fileName.toLowerCase().contains('unsafe')) {
      throw ServerException(
        '"$fileName" uygunsuz içerik nedeniyle reddedildi.',
      );
    }
  }
}
