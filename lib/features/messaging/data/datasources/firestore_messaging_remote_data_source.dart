import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import 'messaging_remote_data_source.dart';

/// FR-5 on real Firestore, **without Cloud Functions** (Spark plan) and
/// **without a live listener**. Each call is a one-shot read/write, not a
/// stream — a message the other party sends only appears once this
/// conversation is reopened (leaving `/chat` and coming back re-runs
/// [openConversation]). Upgrading to push updates needs a `Stream`-based
/// repository interface and a `ChatCubit` that subscribes to it instead of
/// awaiting a single `Future`; deferred to keep this migration a pure
/// data-source swap, same guarantee as every other feature so far.
///
/// Data shape: messages live in `matches/{matchId}/messages/{id}` (`text`,
/// `senderId`, `sentAt`), ordered by `sentAt`; immutable once written. The
/// one-time family nudge flag (FR-5.2) is a `familyNudgeShown` field on the
/// `matches/{matchId}` doc itself, shared by both participants — same
/// behaviour as the mock. `otherPartyName`/`otherPartyAvatarSeed` are
/// denormalized display data the screen already has (see `Conversation`'s
/// doc comment) and aren't stored in Firestore; cached here per matchId so
/// [sendMessage] can still return a fully-formed [Conversation].
class FirestoreMessagingRemoteDataSource implements MessagingRemoteDataSource {
  final Map<String, ({String name, int avatarSeed})> _display = {};

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ServerException('Oturum bulunamadı. Tekrar giriş yap.');
    }
    return user.uid;
  }

  @override
  Future<Conversation> openConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) async {
    _display[matchId] = (name: otherPartyName, avatarSeed: otherPartyAvatarSeed);
    try {
      return await _load(matchId);
    } on FirebaseException catch (e) {
      throw ServerException('Sohbet yüklenemedi (${e.code}).');
    }
  }

  @override
  Future<Conversation> sendMessage({
    required String matchId,
    required String text,
  }) async {
    try {
      await _db.collection('matches').doc(matchId).collection('messages').add({
        'text': text,
        'senderId': _uid,
        'sentAt': FieldValue.serverTimestamp(),
      });
      return await _load(matchId);
    } on FirebaseException catch (e) {
      throw ServerException(
        e.code == 'permission-denied'
            ? 'Mesaj gönderilemedi: izin yok.'
            : 'Mesaj gönderilemedi (${e.code}).',
      );
    }
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

  Future<Conversation> _load(String matchId) async {
    final me = _uid;
    final display = _display[matchId];
    final results = await Future.wait([
      _db.collection('matches').doc(matchId).get(),
      _db
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .orderBy('sentAt')
          .get(),
    ]);
    final matchDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final messagesSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    return Conversation(
      matchId: matchId,
      otherPartyName: display?.name ?? '',
      otherPartyAvatarSeed: display?.avatarSeed ?? 0,
      messages: messagesSnap.docs
          .map((d) => _toMessage(d.id, d.data(), me))
          .toList(),
      familyNudgeShown: (matchDoc.data()?['familyNudgeShown'] as bool?) ?? false,
    );
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
