import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import 'messaging_remote_data_source.dart';

/// FR-5 on real Firestore, **without Cloud Functions** (Spark plan). Live:
/// [watchConversation] combines two Firestore listeners — the messages
/// subcollection and the match doc's `familyNudgeShown` flag — so a
/// message from the other party, or either side dismissing the nudge,
/// shows up in an already-open chat without reopening it.
///
/// Data shape: messages live in `matches/{matchId}/messages/{id}` (`text`,
/// `senderId`, `sentAt`), ordered by `sentAt`; immutable once written. The
/// one-time family nudge flag (FR-5.2) is a `familyNudgeShown` field on the
/// `matches/{matchId}` doc itself, shared by both participants.
class FirestoreMessagingRemoteDataSource implements MessagingRemoteDataSource {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ServerException('Oturum bulunamadı. Tekrar giriş yap.');
    }
    return user.uid;
  }

  @override
  Stream<Conversation> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) {
    late final StreamController<Conversation> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? messagesSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? matchSub;
    List<ChatMessage>? latestMessages;
    bool? latestNudgeShown;

    void emitIfReady() {
      if (latestMessages == null || latestNudgeShown == null) return;
      controller.add(
        Conversation(
          matchId: matchId,
          otherPartyName: otherPartyName,
          otherPartyAvatarSeed: otherPartyAvatarSeed,
          messages: latestMessages!,
          familyNudgeShown: latestNudgeShown!,
        ),
      );
    }

    controller = StreamController<Conversation>(
      onListen: () {
        final String me;
        try {
          me = _uid;
        } on ServerException catch (e) {
          controller.addError(e);
          unawaited(controller.close());
          return;
        }
        matchSub = _db
            .collection('matches')
            .doc(matchId)
            .snapshots()
            .listen(
              (doc) {
                latestNudgeShown =
                    (doc.data()?['familyNudgeShown'] as bool?) ?? false;
                emitIfReady();
              },
              onError: (Object e) {
                if (e is FirebaseException) {
                  controller.addError(
                    ServerException('Sohbet yüklenemedi (${e.code}).'),
                  );
                } else {
                  controller.addError(e);
                }
              },
            );
        messagesSub = _db
            .collection('matches')
            .doc(matchId)
            .collection('messages')
            .orderBy('sentAt')
            .snapshots()
            .listen(
              (snap) {
                latestMessages = snap.docs
                    .map((d) => _toMessage(d.id, d.data(), me))
                    .toList();
                emitIfReady();
              },
              onError: (Object e) {
                if (e is FirebaseException) {
                  controller.addError(
                    ServerException('Sohbet yüklenemedi (${e.code}).'),
                  );
                } else {
                  controller.addError(e);
                }
              },
            );
      },
      onCancel: () async {
        await messagesSub?.cancel();
        await matchSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> sendMessage({
    required String matchId,
    required String text,
  }) async {
    try {
      await _db.collection('matches').doc(matchId).collection('messages').add({
        'text': text,
        'senderId': _uid,
        'sentAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Mesaj gönderilemedi: izin yok.'
            : 'Mesaj gönderilemedi (${e.code}).',
      );
    }
  }

  /// One live `limit(1)` listener per match (participants can already read
  /// a match's messages, so no rules change). Emits once every match has
  /// reported, so the list doesn't flicker or reorder on partial data.
  @override
  Stream<Map<String, ChatMessage>> watchLastMessages(List<String> matchIds) {
    if (matchIds.isEmpty) return Stream.value(const {});

    late final StreamController<Map<String, ChatMessage>> controller;
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    // A key is present once that match has reported; null = no messages.
    final latest = <String, ChatMessage?>{};

    controller = StreamController<Map<String, ChatMessage>>(
      onListen: () {
        final String me;
        try {
          me = _uid;
        } on ServerException catch (e) {
          controller.addError(e);
          unawaited(controller.close());
          return;
        }
        for (final id in matchIds) {
          subs.add(
            _db
                .collection('matches')
                .doc(id)
                .collection('messages')
                .orderBy('sentAt', descending: true)
                .limit(1)
                .snapshots()
                .listen(
                  (snap) {
                    latest[id] = snap.docs.isEmpty
                        ? null
                        : _toMessage(
                            snap.docs.first.id,
                            snap.docs.first.data(),
                            me,
                          );
                    if (latest.length < matchIds.length) return;
                    controller.add({
                      for (final e in latest.entries)
                        if (e.value != null) e.key: e.value!,
                    });
                  },
                  onError: (Object e) {
                    controller.addError(
                      e is FirebaseException
                          ? ServerException('Mesajlar yüklenemedi (${e.code}).')
                          : e,
                    );
                  },
                ),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<void> dismissFamilyNudge(String matchId) async {
    try {
      await _db.collection('matches').doc(matchId).update({
        'familyNudgeShown': true,
      });
    } on FirebaseException catch (e) {
      throw ServerException('İşlem tamamlanamadı (${e.code}).');
    }
  }

  ChatMessage _toMessage(String id, Map<String, dynamic> data, String me) {
    final sentAt = data['sentAt'] as Timestamp?;
    return ChatMessage(
      id: id,
      text: data['text'] as String,
      // Briefly null right after an unsynced server-timestamp write; falls
      // back to "now" rather than crashing the list.
      sentAt: sentAt?.toDate() ?? DateTime.now(),
      sender: data['senderId'] == me ? MessageSender.me : MessageSender.them,
    );
  }
}
