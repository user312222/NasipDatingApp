import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

abstract interface class MessagingRemoteDataSource {
  Stream<Conversation> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  });
  Future<void> sendMessage({required String matchId, required String text});
  Future<Map<String, ChatMessage>> getLastMessages(List<String> matchIds);
  Future<void> dismissFamilyNudge(String matchId);
}
