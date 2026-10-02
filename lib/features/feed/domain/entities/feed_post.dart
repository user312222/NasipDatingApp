import 'package:equatable/equatable.dart';

/// One member's answer to the day's question. The author is shown the same
/// way as everywhere else before a match: name, age, city and a gradient
/// initial - never a photo (FR-3).
class FeedPost extends Equatable {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAge,
    required this.authorCity,
    required this.avatarColorSeed,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.likedByMe = false,
    this.isMine = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final int authorAge;
  final String authorCity;
  final int avatarColorSeed;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final bool likedByMe;
  final bool isMine;

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorAge,
    authorCity,
    avatarColorSeed,
    text,
    createdAt,
    likeCount,
    likedByMe,
    isMine,
  ];
}
