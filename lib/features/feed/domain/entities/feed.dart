import 'package:equatable/equatable.dart';

import 'daily_question.dart';
import 'feed_post.dart';

/// Today's question plus every answer the current user may see (newest
/// first, people they blocked left out).
class Feed extends Equatable {
  const Feed({required this.question, required this.posts});

  final DailyQuestion question;
  final List<FeedPost> posts;

  /// The current user's own answer for today, if they gave one.
  FeedPost? get mine {
    for (final post in posts) {
      if (post.isMine) return post;
    }
    return null;
  }

  List<FeedPost> get others => [
    for (final post in posts)
      if (!post.isMine) post,
  ];

  @override
  List<Object?> get props => [question, posts];
}
