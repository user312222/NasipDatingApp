import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/family_visible_match.dart';
import '../../domain/entities/relationship.dart';
import 'family_remote_data_source.dart';

/// FR-8 on real Firestore, **without Cloud Functions** (Spark plan).
///
/// Collections (all new, family-only):
/// - `familyInviteCodes/{singleUserId}` — a single user's own code,
///   created once, immutable.
/// - `familyInviteCodeLookup/{code}` — the reverse index a guardian needs
///   to resolve a typed code to a `singleUserId`; created in the same
///   write as the doc above.
/// - `guardianOf/{guardianUserId}` — FR-8.2/8.3: one row per guardian,
///   pointing at the single user they linked to.
///
/// The actual match data a guardian sees comes from `matching`'s
/// `familyVisible` collection (see `FirestoreMatchingRemoteDataSource`) —
/// this data source never reads `matches` directly, only `familyVisible`
/// + `publicProfiles`, matching the "family reads matching's store at the
/// data layer only" pattern already used by the mock.
class FirestoreFamilyRemoteDataSource implements FamilyRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 8;

  @override
  Future<String> getOrCreateInviteCode(String singleUserId) async {
    try {
      final existing = await _db
          .collection('familyInviteCodes')
          .doc(singleUserId)
          .get();
      final existingCode = existing.data()?['code'] as String?;
      if (existingCode != null) return existingCode;

      // Astronomically unlikely to collide, but retry a few times rather
      // than trust that blindly.
      for (var attempt = 0; attempt < 5; attempt++) {
        final code = _generateCode();
        final lookupRef = _db.collection('familyInviteCodeLookup').doc(code);
        if ((await lookupRef.get()).exists) continue;
        try {
          final batch = _db.batch();
          batch.set(_db.collection('familyInviteCodes').doc(singleUserId), {
            'code': code,
          });
          batch.set(lookupRef, {'singleUserId': singleUserId});
          await batch.commit();
          return code;
        } on FirebaseException {
          continue; // Lost a race for this code — try another.
        }
      }
      throw const ServerException('Kod oluşturulamadı. Tekrar dener misin?');
    } on FirebaseException catch (e) {
      throw ServerException('Kod oluşturulamadı (${e.code}).');
    }
  }

  @override
  Future<void> linkGuardian({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  }) async {
    try {
      final code = inviteCode.trim().toUpperCase();
      final lookup = await _db
          .collection('familyInviteCodeLookup')
          .doc(code)
          .get();
      final singleUserId = lookup.data()?['singleUserId'] as String?;
      if (singleUserId == null) {
        throw const ServerException('Bu aile kodu geçerli değil.');
      }
      if (singleUserId == guardianUserId) {
        throw const ServerException('Kendi kodunla bağlanamazsın.');
      }
      await _db.collection('guardianOf').doc(guardianUserId).set({
        'singleUserId': singleUserId,
        'guardianName': guardianName,
        'relationship': relationship.name,
        'linkedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Bağlantı kurulamadı (${e.code}).');
    }
  }

  @override
  Future<List<FamilyVisibleMatch>> getVisibleMatches(
    String guardianUserId,
  ) async {
    try {
      final link = await _db.collection('guardianOf').doc(guardianUserId).get();
      final singleUserId = link.data()?['singleUserId'] as String?;
      if (singleUserId == null) {
        throw const ServerException('Önce bir hesaba bağlanmalısın.');
      }

      final visible = await _db
          .collection('familyVisible')
          .where('singleUserId', isEqualTo: singleUserId)
          .get();

      final matches = await Future.wait(
        visible.docs.map((doc) async {
          final data = doc.data();
          final otherUserId = data['otherUserId'] as String?;
          if (otherUserId == null) return null;
          final profile = await _db
              .collection('publicProfiles')
              .doc(otherUserId)
              .get();
          final pdata = profile.data();
          if (pdata == null) return null;
          final matchedAt =
              (data['matchedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return FamilyVisibleMatch(
            candidateName: pdata['name'] as String,
            candidateAge: _ageFrom(pdata['birthDate'] as Timestamp),
            candidateCity: pdata['city'] as String,
            // See REQUIREMENTS.md §7 — an open item on how detailed this
            // should get; kept coarse and time-based like the mock.
            statusLabel: DateTime.now().difference(matchedAt).inDays < 1
                ? 'Yeni eşleşme'
                : 'Aktif yazışıyorlar',
            matchedAt: matchedAt,
          );
        }),
      );
      return matches.whereType<FamilyVisibleMatch>().toList()
        ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
    } on FirebaseException catch (e) {
      throw ServerException('Eşleşmeler yüklenemedi (${e.code}).');
    }
  }

  int _ageFrom(Timestamp birthDate) {
    final birth = birthDate.toDate();
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  String _generateCode() {
    final rnd = Random();
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
    ).join();
  }
}
