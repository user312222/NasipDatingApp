import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/messaging_repository.dart';

class MarkConversationRead implements UseCase<void, String> {
  const MarkConversationRead(this._repository);
  final MessagingRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.markConversationRead(params);
}
