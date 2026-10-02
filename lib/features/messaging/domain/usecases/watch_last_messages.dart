import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';
import '../repositories/messaging_repository.dart';

class WatchLastMessagesParams extends Equatable {
  const WatchLastMessagesParams(this.matchIds);
  final List<String> matchIds;

  @override
  List<Object?> get props => [matchIds];
}

/// Live latest message per match, for list previews. Matches without any
/// message are absent from the emitted map. Like `WatchConversation`, not a
/// `UseCase` — that interface is shaped for a single `Future`.
class WatchLastMessages {
  const WatchLastMessages(this._repository);
  final MessagingRepository _repository;

  Stream<Result<Map<String, ChatMessage>>> call(
    WatchLastMessagesParams params,
  ) => _repository.watchLastMessages(params.matchIds);
}
