import '../../../../core/result/result.dart';
import '../entities/feed.dart';

abstract interface class FeedRepository {
  /// Live view of today's question and its answers.
  Stream<Result<Feed>> watchToday();

  /// One answer per user per day; a second attempt fails.
  Future<Result<void>> submitAnswer(String text);

  /// Removes the current user's answer for today.
  Future<Result<void>> deleteMyAnswer();

  /// A feed like is only a reaction - it never creates a match and never
  /// opens a conversation.
  Future<Result<void>> setLiked({required String postId, required bool liked});
}
