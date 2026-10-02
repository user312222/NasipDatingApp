import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class WatchConversationParams extends Equatable {
  const WatchConversationParams({
    required this.matchId,
    required this.otherPartyName,
    required this.otherPartyAvatarSeed,
  });

  final String matchId;
  final String otherPartyName;
  final int otherPartyAvatarSeed;

  @override
  List<Object?> get props => [matchId, otherPartyName, otherPartyAvatarSeed];
}

/// Doesn't implement `UseCase<R, Params>` — that interface is shaped for a
/// single `Future<Result<R>>`, not an ongoing `Stream`.
class WatchConversation {
  const WatchConversation(this._repository);
  final MessagingRepository _repository;

  Stream<Result<Conversation>> call(WatchConversationParams params) =>
      _repository.watchConversation(
        matchId: params.matchId,
        otherPartyName: params.otherPartyName,
        otherPartyAvatarSeed: params.otherPartyAvatarSeed,
      );
}
