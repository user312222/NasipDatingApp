import '../../../../core/result/result.dart';
import '../repositories/messaging_repository.dart';

/// When the current user last opened each conversation (match id -> time).
/// Like `WatchConversation`, not a `UseCase` — that interface is shaped for
/// a single `Future`.
class WatchReadTimes {
  const WatchReadTimes(this._repository);
  final MessagingRepository _repository;

  Stream<Result<Map<String, DateTime>>> call() => _repository.watchReadTimes();
}
