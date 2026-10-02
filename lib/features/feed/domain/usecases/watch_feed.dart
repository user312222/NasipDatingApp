import '../../../../core/result/result.dart';
import '../entities/feed.dart';
import '../repositories/feed_repository.dart';

/// Not a `UseCase` - that interface is shaped for a single `Future`.
class WatchFeed {
  const WatchFeed(this._repository);
  final FeedRepository _repository;

  Stream<Result<Feed>> call() => _repository.watchToday();
}
