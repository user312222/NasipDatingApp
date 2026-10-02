import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/error_log.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/daily_question.dart';
import '../../domain/entities/feed.dart';
import '../../domain/entities/feed_post.dart';
import 'feed_remote_data_source.dart';

/// The "question of the day" feed on Firestore, without Cloud Functions.
///
/// - `feedPosts/{uid}_{dayKey}` -> {authorId, dayKey, text, createdAt,
///   likeCount}. The doc id is what caps a user at one answer per day -
///   the rules force it to be the caller's uid plus today's UTC date.
/// - `feedLikes/{postId}_{uid}` -> {postId, userId, dayKey, createdAt}. A
///   like and the post's `likeCount` change in one batch; the rules only
///   accept a count that moves by exactly one together with the caller's
///   own like doc appearing/disappearing.
///
/// Author name/age/city are joined from `publicProfiles` (already readable
/// by signed-in users) instead of being copied into each post, so a post
/// never carries more than the public profile already shows. People the
/// current user blocked are left out, same as in discovery.
///
/// There is no automatic moderation of the text (that needs a server) -
/// the safety net is the 280-character limit, one answer per day, and the
/// report/block menu on every answer.
class FirestoreFeedRemoteDataSource implements FeedRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  final _authors = <String, _Author?>{};

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ServerException('Oturum bulunamadı. Tekrar giriş yap.');
    }
    return user.uid;
  }

  @override
  Stream<Feed> watchToday() {
    late final StreamController<Feed> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? postsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? likesSub;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? posts;
    Set<String>? likedPostIds;
    var blocked = <String>{};
    var generation = 0;

    final question = DailyQuestion.forDay(DateTime.now());

    Future<void> publish(String me) async {
      final docs = posts;
      final liked = likedPostIds;
      if (docs == null || liked == null) return;
      final mine = ++generation;
      await _loadAuthors({
        for (final d in docs) d.data()['authorId'] as String,
      });
      // A newer snapshot arrived while the profiles were loading.
      if (mine != generation || controller.isClosed) return;

      final result = <FeedPost>[];
      for (final doc in docs) {
        final data = doc.data();
        final authorId = data['authorId'] as String;
        final author = _authors[authorId];
        if (author == null || blocked.contains(authorId)) continue;
        result.add(
          FeedPost(
            id: doc.id,
            authorId: authorId,
            authorName: author.name,
            authorAge: author.age,
            authorCity: author.city,
            avatarColorSeed: authorId.codeUnits.fold<int>(0, (a, b) => a + b),
            text: data['text'] as String,
            // Null only while our own write is still pending.
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
            likedByMe: liked.contains(doc.id),
            isMine: authorId == me,
          ),
        );
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(Feed(question: question, posts: result));
    }

    void fail(Object e) {
      if (e is FirebaseException) {
        logFailure('feed.stream', e);
        controller.addError(const ServerException('Akış yüklenemedi.'));
      } else {
        controller.addError(e);
      }
    }

    controller = StreamController<Feed>(
      onListen: () async {
        final String me;
        try {
          me = _uid;
        } on ServerException catch (e) {
          controller.addError(e);
          unawaited(controller.close());
          return;
        }
        try {
          final snap = await _db
              .collection('blockedUsers')
              .where('blockerId', isEqualTo: me)
              .get();
          blocked = {
            for (final d in snap.docs) d.data()['blockedId'] as String,
          };
        } on FirebaseException catch (e) {
          // Not fatal: the feed still works, it just can't hide anyone.
          logFailure('feed.blocked', e);
        }
        if (controller.isClosed) return;

        postsSub = _db
            .collection('feedPosts')
            .where('dayKey', isEqualTo: question.dayKey)
            .snapshots()
            .listen((snap) {
              posts = snap.docs;
              unawaited(publish(me));
            }, onError: fail);
        likesSub = _db
            .collection('feedLikes')
            .where('userId', isEqualTo: me)
            .where('dayKey', isEqualTo: question.dayKey)
            .snapshots()
            .listen((snap) {
              likedPostIds = {
                for (final d in snap.docs) d.data()['postId'] as String,
              };
              unawaited(publish(me));
            }, onError: fail);
      },
      onCancel: () async {
        await Future.wait([
          if (postsSub != null) postsSub!.cancel(),
          if (likesSub != null) likesSub!.cancel(),
        ]);
      },
    );
    return controller.stream;
  }

  Future<void> _loadAuthors(Set<String> ids) async {
    final missing = ids.where((id) => !_authors.containsKey(id)).toList();
    if (missing.isEmpty) return;
    try {
      final docs = await Future.wait(
        missing.map((id) => _db.collection('publicProfiles').doc(id).get()),
      );
      for (var i = 0; i < missing.length; i++) {
        final data = docs[i].data();
        // A deleted account leaves its answers behind; they're just hidden.
        _authors[missing[i]] = data == null ? null : _Author.fromProfile(data);
      }
    } on FirebaseException catch (e) {
      logFailure('feed.authors', e);
    }
  }

  @override
  Future<void> submitAnswer(String text) async {
    try {
      final me = _uid;
      final dayKey = DailyQuestion.dayKeyFor(DateTime.now());
      await _db.collection('feedPosts').doc('${me}_$dayKey').set({
        'authorId': me,
        'dayKey': dayKey,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'likeCount': 0,
      });
    } on FirebaseException catch (e) {
      logFailure('feed.submit', e);
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Cevabın paylaşılamadı. Bugün zaten cevap vermiş olabilirsin.'
            : 'Cevabın paylaşılamadı.',
      );
    }
  }

  @override
  Future<void> deleteMyAnswer() async {
    try {
      final dayKey = DailyQuestion.dayKeyFor(DateTime.now());
      await _db.collection('feedPosts').doc('${_uid}_$dayKey').delete();
    } on FirebaseException catch (e) {
      logFailure('feed.delete', e);
      throw const ServerException('Cevabın silinemedi.');
    }
  }

  @override
  Future<void> setLiked({required String postId, required bool liked}) async {
    try {
      final me = _uid;
      final post = _db.collection('feedPosts').doc(postId);
      final like = _db.collection('feedLikes').doc('${postId}_$me');
      final batch = _db.batch();
      if (liked) {
        batch.set(like, {
          'postId': postId,
          'userId': me,
          'dayKey': DailyQuestion.dayKeyFor(DateTime.now()),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.delete(like);
      }
      batch.update(post, {'likeCount': FieldValue.increment(liked ? 1 : -1)});
      await batch.commit();
    } on FirebaseException catch (e) {
      logFailure('feed.like', e);
      throw const ServerException('Beğeni kaydedilemedi.');
    }
  }
}

class _Author {
  const _Author({required this.name, required this.age, required this.city});

  factory _Author.fromProfile(Map<String, dynamic> data) {
    final birth = (data['birthDate'] as Timestamp).toDate();
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return _Author(
      name: data['name'] as String,
      age: age,
      city: data['city'] as String,
    );
  }

  final String name;
  final int age;
  final String city;
}
