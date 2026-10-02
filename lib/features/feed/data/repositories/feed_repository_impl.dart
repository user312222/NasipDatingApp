import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/feed.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_source.dart';

class FeedRepositoryImpl implements FeedRepository {
  const FeedRepositoryImpl({required this.remoteDataSource});

  final FeedRemoteDataSource remoteDataSource;

  @override
  Stream<Result<Feed>> watchToday() async* {
    try {
      await for (final feed in remoteDataSource.watchToday()) {
        yield Ok(feed);
      }
    } on ServerException catch (e) {
      yield Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }

  @override
  Future<Result<void>> submitAnswer(String text) =>
      _guard(() => remoteDataSource.submitAnswer(text));

  @override
  Future<Result<void>> deleteMyAnswer() =>
      _guard(remoteDataSource.deleteMyAnswer);

  @override
  Future<Result<void>> setLiked({
    required String postId,
    required bool liked,
  }) => _guard(() => remoteDataSource.setLiked(postId: postId, liked: liked));

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }
}
