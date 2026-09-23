import 'dart:math';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

/// **Placeholder data source.** Stands in for a real-time backend
/// (Firestore listeners, most likely) — swap without touching
/// `MessagingRepositoryImpl` or anything above it.
///
/// Seeds one conversation (`match_c1`, matching the "already likes you"
/// candidate Zeynep from `MockMatchingRemoteDataSource`) with messages
/// dated 8 days ago, so FR-5.2's 7-day trigger is actually reachable
/// while testing — without it, only the 30-message trigger could ever be
/// exercised by hand.
abstract interface class MessagingRemoteDataSource {
  Future<Conversation> openConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  });
  Future<Conversation> sendMessage({
    required String matchId,
    required String text,
  });
  Future<void> dismissFamilyNudge(String matchId);
}

class MockMessagingRemoteDataSource implements MessagingRemoteDataSource {
  final Map<String, Conversation> _conversations = {
    'match_c1': Conversation(
      matchId: 'match_c1',
      otherPartyName: 'Zeynep',
      otherPartyAvatarSeed: 1,
      messages: [
        ChatMessage(
          id: 'seed_1',
          text: 'Merhaba, eşleştiğimize sevindim!',
          sentAt: DateTime.now().subtract(const Duration(days: 8)),
          sender: MessageSender.them,
        ),
        ChatMessage(
          id: 'seed_2',
          text: 'Ben de! Nasılsın?',
          sentAt: DateTime.now().subtract(const Duration(days: 7, hours: 23)),
          sender: MessageSender.me,
        ),
        ChatMessage(
          id: 'seed_3',
          text: 'İyiyim, teşekkürler. Sen İstanbul’da mı yaşıyorsun?',
          sentAt: DateTime.now().subtract(const Duration(days: 7, hours: 12)),
          sender: MessageSender.them,
        ),
      ],
    ),
  };

  @override
  Future<Conversation> openConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _conversations.putIfAbsent(
      matchId,
      () => Conversation(
        matchId: matchId,
        otherPartyName: otherPartyName,
        otherPartyAvatarSeed: otherPartyAvatarSeed,
        messages: const [],
      ),
    );
  }

  @override
  Future<Conversation> sendMessage({
    required String matchId,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final existing = _conversations[matchId];
    if (existing == null) {
      throw const ServerException('Sohbet bulunamadı.');
    }
    final message = ChatMessage(
      id: 'm_${Random().nextInt(999999)}',
      text: text,
      sentAt: DateTime.now(),
      sender: MessageSender.me,
    );
    final updated = existing.copyWith(
      messages: [...existing.messages, message],
    );
    _conversations[matchId] = updated;
    return updated;
  }

  @override
  Future<void> dismissFamilyNudge(String matchId) async {
    final existing = _conversations[matchId];
    if (existing == null) return;
    _conversations[matchId] = existing.copyWith(familyNudgeShown: true);
  }
}
