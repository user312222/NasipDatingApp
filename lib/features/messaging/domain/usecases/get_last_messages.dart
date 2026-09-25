import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/messaging_repository.dart';

class GetLastMessagesParams extends Equatable {
  const GetLastMessagesParams(this.matchIds);
  final List<String> matchIds;

  @override
  List<Object?> get props => [matchIds];
}

/// Latest message per match, for list previews. Matches without any
/// message are absent from the returned map.
class GetLastMessages
    implements UseCase<Map<String, ChatMessage>, GetLastMessagesParams> {
  const GetLastMessages(this._repository);
  final MessagingRepository _repository;

  @override
  Future<Result<Map<String, ChatMessage>>> call(GetLastMessagesParams params) =>
      _repository.getLastMessages(params.matchIds);
}
