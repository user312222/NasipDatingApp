import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class OpenConversationParams extends Equatable {
  const OpenConversationParams({
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

class OpenConversation implements UseCase<Conversation, OpenConversationParams> {
  const OpenConversation(this._repository);
  final MessagingRepository _repository;

  @override
  Future<Result<Conversation>> call(OpenConversationParams params) => _repository.openConversation(
    matchId: params.matchId,
    otherPartyName: params.otherPartyName,
    otherPartyAvatarSeed: params.otherPartyAvatarSeed,
  );
}
