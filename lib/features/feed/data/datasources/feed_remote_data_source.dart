import '../../domain/entities/feed.dart';

abstract interface class FeedRemoteDataSource {
  Stream<Feed> watchToday();
  Stream<bool> watchAnsweredToday();
  Future<void> submitAnswer(String text);
  Future<void> deleteMyAnswer();
  Future<void> setLiked({required String postId, required bool liked});
}
