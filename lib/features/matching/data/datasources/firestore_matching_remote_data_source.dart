import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/error_log.dart';
import '../../../../core/error/exceptions.dart';
import '../../../safety/data/datasources/safety_remote_data_source.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import 'matching_remote_data_source.dart';

/// FR-4 on real Firestore, **without Cloud Functions** (Spark plan).
///
/// Collections:
/// - `publicProfiles/{uid}` — the only profile fields other users may see.
/// - `likes/{from}_{to}` — one doc per like; readable by both parties.
/// - `likeCounters/{uid}_{utcYYYY-M-D}` — FR-4.3 daily cap; the rules
///   refuse a like whose counter isn't bumped by exactly one, and refuse a
///   counter above [_dailyLikeLimit], so the cap holds even against a
///   modified client.
/// - `matches/{uidA}_{uidB}` (ids sorted) — created by the client whose
///   like completes a mutual pair; rules require both likes to exist.
/// - `familyVisible/{matchId}_{singleUserId}` — FR-8.4: existence means
///   `singleUserId` opted to show this match to their own linked guardian
///   (see `features/family`). Kept as its own collection rather than a
///   per-uid map field on `matches`, because Firestore can't index a
///   dynamic map key — a guardian's `visibleToFamily`-filtered query needs
///   a real field to filter on.
///
/// Known gaps until Cloud Functions (Blaze) take over — see
/// `firestore.rules`: a person can technically read who liked them, and two
/// simultaneous likes can miss each other (reconciled on [getMyMatches]).
class FirestoreMatchingRemoteDataSource implements MatchingRemoteDataSource {
  FirestoreMatchingRemoteDataSource(this._safety);

  /// Block list (FR-6.2) — still the mock safety store for now.
  final SafetyRemoteDataSource _safety;

  static const _dailyLikeLimit = 12;
  static const _feedLimit = 100;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ServerException('Oturum bulunamadı. Tekrar giriş yap.');
    }
    return user.uid;
  }

  /// UTC day key; must match the one `firestore.rules` derives from
  /// `request.time` (no zero padding).
  String _dayKey() {
    final d = DateTime.now().toUtc();
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  Future<List<Candidate>> getCandidates(CandidateFilter filter) async {
    try {
      final me = _uid;
      Query<Map<String, dynamic>> query = _db.collection('publicProfiles');
      if (filter.intent != null) {
        query = query.where('intent', isEqualTo: filter.intent!.name);
      }
      final profiles = await query.limit(_feedLimit).get();
      final myLikes = await _db
          .collection('likes')
          .where('from', isEqualTo: me)
          .get();
      final blocked = await _safety.getBlockedIds();
      final liked = {for (final d in myLikes.docs) d.data()['to'] as String};

      final city = filter.city?.trim().toLowerCase();
      return profiles.docs
          .where((d) => d.id != me)
          .where((d) => !blocked.contains(d.id) && !liked.contains(d.id))
          .map((d) => _toCandidate(d.id, d.data()))
          .where((c) {
            if (city != null && city.isNotEmpty) {
              if (c.city.toLowerCase() != city) return false;
            }
            if (filter.minAge != null && c.age < filter.minAge!) return false;
            if (filter.maxAge != null && c.age > filter.maxAge!) return false;
            return true;
          })
          .toList();
    } on FirebaseException catch (e) {
      logFailure('matching', e);
      throw const ServerException('Adaylar yüklenemedi.');
    }
  }

  @override
  Future<SwipeOutcome> swipe({
    required Candidate candidate,
    required SwipeAction action,
  }) async {
    if (action == SwipeAction.pass) {
      return const SwipeOutcome(matched: false);
    }
    try {
      final me = _uid;
      final other = candidate.id;
      final likeRef = _db.collection('likes').doc('${me}_$other');
      final counterRef = _db
          .collection('likeCounters')
          .doc('${me}_${_dayKey()}');

      final counter = await counterRef.get();
      final used = (counter.data()?['count'] as int?) ?? 0;
      if (used >= _dailyLikeLimit) {
        throw const ServerException(
          'Bugünkü beğeni hakkın doldu. Yarın devam edebilirsin.',
        );
      }
      if ((await likeRef.get()).exists) {
        return const SwipeOutcome(matched: false);
      }
      final reverse = await _db.collection('likes').doc('${other}_$me').get();
      final theyLikedMe = reverse.exists;

      final batch = _db.batch();
      batch.set(likeRef, {
        'from': me,
        'to': other,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(counterRef, {'uid': me, 'count': used + 1});
      final matchId = _matchId(me, other);
      if (theyLikedMe) {
        batch.set(
          _db.collection('matches').doc(matchId),
          _newMatchData(me, other),
        );
      }
      await batch.commit();

      if (!theyLikedMe) return const SwipeOutcome(matched: false);
      return SwipeOutcome(
        matched: true,
        match: Match(
          id: matchId,
          candidate: candidate,
          matchedAt: DateTime.now(),
        ),
      );
    } on FirebaseException catch (e) {
      logFailure('matching', e);
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Beğeni kaydedilemedi. Günlük hakkın dolmuş olabilir.'
            : 'Beğeni kaydedilemedi.',
      );
    }
  }

  @override
  Future<List<Match>> getMyMatches() async {
    try {
      final me = _uid;
      final matchesQuery = _db
          .collection('matches')
          .where('users', arrayContains: me);
      var snap = await matchesQuery.get();
      final repaired = await _reconcileMutualLikes(
        me,
        snap.docs.map((d) => d.id).toSet(),
      );
      if (repaired) snap = await matchesQuery.get();
      final blocked = await _safety.getBlockedIds();
      final visibleSnap = await _db
          .collection('familyVisible')
          .where('singleUserId', isEqualTo: me)
          .get();
      final visibleMatchIds = {
        for (final d in visibleSnap.docs) d.data()['matchId'] as String,
      };

      final matches = await Future.wait(
        snap.docs.map((doc) async {
          final data = doc.data();
          final users = List<String>.from(data['users'] as List);
          final other = users.firstWhere((u) => u != me);
          if (blocked.contains(other)) return null;
          final profile = await _db
              .collection('publicProfiles')
              .doc(other)
              .get();
          return Match(
            id: doc.id,
            candidate: profile.exists
                ? _toCandidate(other, profile.data()!)
                : Candidate(
                    id: other,
                    name: 'Kullanıcı',
                    age: 18,
                    city: '',
                    intent: CandidateIntent.notSureYet,
                    avatarColorSeed: 1,
                  ),
            matchedAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            visibleToFamily: visibleMatchIds.contains(doc.id),
          );
        }),
      );
      return matches.whereType<Match>().toList()
        ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
    } on FirebaseException catch (e) {
      logFailure('matching', e);
      throw const ServerException('Eşleşmeler yüklenemedi.');
    }
  }

  @override
  Future<void> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) async {
    try {
      final me = _uid;
      final ref = _db.collection('familyVisible').doc('${matchId}_$me');
      if (!visible) {
        await ref.delete();
        return;
      }
      final match = await _db.collection('matches').doc(matchId).get();
      final users = List<String>.from(
        (match.data()?['users'] as List?) ?? const [],
      );
      final other = users.firstWhere((u) => u != me, orElse: () => '');
      if (other.isEmpty) {
        throw const ServerException('Eşleşme bulunamadı.');
      }
      await ref.set({
        'singleUserId': me,
        'matchId': matchId,
        'otherUserId': other,
        'matchedAt': match.data()?['createdAt'],
        'markedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      logFailure('matching', e);
      throw const ServerException('Ayar kaydedilemedi.');
    }
  }

  /// Two people liking each other at the same moment each see "no like
  /// yet" and neither creates the match. Whoever loads matches next fixes
  /// it: for every like I received that I also sent, make sure the match
  /// exists. Best effort — failures are ignored, the next load retries.
  /// Returns whether it created at least one match.
  Future<bool> _reconcileMutualLikes(
    String me,
    Set<String> existingMatchIds,
  ) async {
    var created = false;
    try {
      final incoming = await _db
          .collection('likes')
          .where('to', isEqualTo: me)
          .get();
      for (final like in incoming.docs) {
        final from = like.data()['from'] as String;
        final matchId = _matchId(me, from);
        if (existingMatchIds.contains(matchId)) continue;
        final mine = await _db.collection('likes').doc('${me}_$from').get();
        if (!mine.exists) continue;
        await _db
            .collection('matches')
            .doc(matchId)
            .set(_newMatchData(me, from));
        created = true;
      }
    } on FirebaseException {
      // Best effort.
    }
    return created;
  }

  String _matchId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Map<String, dynamic> _newMatchData(String a, String b) {
    final ids = [a, b]..sort();
    return {'users': ids, 'createdAt': FieldValue.serverTimestamp()};
  }

  Candidate _toCandidate(String uid, Map<String, dynamic> data) {
    final birth = (data['birthDate'] as Timestamp).toDate();
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return Candidate(
      id: uid,
      name: data['name'] as String,
      age: age,
      city: data['city'] as String,
      intent: data['intent'] == 'marriage'
          ? CandidateIntent.marriage
          : CandidateIntent.notSureYet,
      // Stable per user; stands in for a photo until Storage is on.
      avatarColorSeed: uid.codeUnits.fold<int>(0, (a, b) => a + b),
      bio: data['occupation'] as String?,
    );
  }
}
