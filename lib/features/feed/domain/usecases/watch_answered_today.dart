import '../../../../core/result/result.dart';
import '../repositories/feed_repository.dart';

/// Not a `UseCase` - that interface is shaped for a single `Future`.
class WatchAnsweredToday {
  const WatchAnsweredToday(this._repository);
  final FeedRepository _repository;

  Stream<Result<bool>> call() => _repository.watchAnsweredToday();
}
