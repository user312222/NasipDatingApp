import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

abstract interface class MessagingRepository {
  /// Live view of the conversation for [matchId] — the first emission is
  /// today's "open", every emission after is a push update (the other
  /// party sent a message, or either side dismissed the family nudge).
  /// [otherPartyName]/[otherPartyAvatarSeed] are denormalized display
  /// fields the screen already has (see [Conversation]'s doc comment),
  /// supplied here since nothing server-side stores them.
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  });

  /// FR-5.1. The live [watchConversation] stream picks up the new message
  /// on its own; this just confirms the write succeeded.
  Future<Result<void>> sendMessage({
    required String matchId,
    required String text,
  });

  /// The most recent message of each given match (for list previews).
  /// Matches with no messages yet are simply absent from the map.
  Future<Result<Map<String, ChatMessage>>> getLastMessages(
    List<String> matchIds,
  );

  /// FR-5.2: mark the one-time nudge as shown so it never appears again
  /// for this conversation.
  Future<Result<void>> dismissFamilyNudge(String matchId);
}
