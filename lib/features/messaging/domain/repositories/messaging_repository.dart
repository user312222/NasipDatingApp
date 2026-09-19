import '../../../../core/result/result.dart';
import '../entities/conversation.dart';

abstract interface class MessagingRepository {
  /// Gets the existing conversation for [matchId], or starts a new empty
  /// one using [otherPartyName]/[otherPartyAvatarSeed] if none exists yet.
  Future<Result<Conversation>> openConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  });

  /// FR-5.1. Returns the updated conversation.
  Future<Result<Conversation>> sendMessage({required String matchId, required String text});

  /// FR-5.2: mark the one-time nudge as shown so it never appears again
  /// for this conversation.
  Future<Result<void>> dismissFamilyNudge(String matchId);
}
