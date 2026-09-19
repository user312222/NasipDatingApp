import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/conversation.dart';
import '../repositories/messaging_repository.dart';

class SendMessageParams extends Equatable {
  const SendMessageParams({required this.matchId, required this.text});
  final String matchId;
  final String text;

  @override
  List<Object?> get props => [matchId, text];
}

class SendMessage implements UseCase<Conversation, SendMessageParams> {
  const SendMessage(this._repository);
  final MessagingRepository _repository;

  @override
  Future<Result<Conversation>> call(SendMessageParams params) =>
      _repository.sendMessage(matchId: params.matchId, text: params.text);
}
