import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/daily_question.dart';
import '../../domain/entities/feed.dart';
import '../../domain/entities/feed_post.dart';
import '../../domain/usecases/delete_my_answer.dart';
import '../../domain/usecases/set_post_liked.dart';
import '../../domain/usecases/submit_answer.dart';
import '../../domain/usecases/watch_feed.dart';

sealed class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

final class FeedLoading extends FeedState {
  const FeedLoading();
}

final class FeedError extends FeedState {
  const FeedError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class FeedLoaded extends FeedState {
  const FeedLoaded(this.feed, {this.isSubmitting = false, this.actionError});

  final Feed feed;
  final bool isSubmitting;

  /// One-shot, like `ChatLoaded.sendError`: shown once in a SnackBar and
  /// gone with the next emission.
  final String? actionError;

  @override
  List<Object?> get props => [feed, isSubmitting, actionError];
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit({
    required WatchFeed watchFeed,
    required SubmitAnswer submitAnswer,
    required DeleteMyAnswer deleteMyAnswer,
    required SetPostLiked setPostLiked,
  }) : _watchFeed = watchFeed,
       _submitAnswer = submitAnswer,
       _deleteMyAnswer = deleteMyAnswer,
       _setPostLiked = setPostLiked,
       super(const FeedLoading());

  final WatchFeed _watchFeed;
  final SubmitAnswer _submitAnswer;
  final DeleteMyAnswer _deleteMyAnswer;
  final SetPostLiked _setPostLiked;
  StreamSubscription<Result<Feed>>? _subscription;

  /// Authors blocked from this screen - hidden at once, before the next
  /// stream emission would catch up.
  final _hiddenAuthors = <String>{};

  void start() {
    emit(const FeedLoading());
    unawaited(_subscription?.cancel());
    _subscription = _watchFeed().listen((result) {
      if (isClosed) return;
      switch (result) {
        case Ok<Feed>(:final value):
          final current = state;
          emit(
            FeedLoaded(
              _withoutHidden(value),
              isSubmitting: current is FeedLoaded && current.isSubmitting,
            ),
          );
        case Err<Feed>(:final failure):
          emit(FeedError(failure.message));
      }
    });
  }

  /// Returns whether the answer was accepted, so the screen knows when to
  /// clear its text field.
  Future<bool> submit(String text) async {
    final current = state;
    final answer = text.trim();
    if (current is! FeedLoaded || current.isSubmitting) return false;
    if (answer.isEmpty) return false;
    if (answer.length > DailyQuestion.maxAnswerLength) {
      emit(
        FeedLoaded(
          current.feed,
          actionError:
              'Cevabın en fazla ${DailyQuestion.maxAnswerLength} karakter olabilir.',
        ),
      );
      return false;
    }

    emit(FeedLoaded(current.feed, isSubmitting: true));
    final result = await _submitAnswer(answer);
    if (isClosed) return false;
    final latest = state;
    if (latest is! FeedLoaded) return false;
    switch (result) {
      case Ok<void>():
        emit(FeedLoaded(latest.feed));
        return true;
      case Err<void>(:final failure):
        emit(FeedLoaded(latest.feed, actionError: failure.message));
        return false;
    }
  }

  Future<void> deleteMine() async {
    final result = await _deleteMyAnswer(const NoParams());
    _reportFailure(result);
  }

  Future<void> toggleLike(FeedPost post) async {
    if (post.isMine) return;
    final result = await _setPostLiked(
      SetPostLikedParams(postId: post.id, liked: !post.likedByMe),
    );
    _reportFailure(result);
  }

  /// Called after the user blocks an author from the feed.
  void hideAuthor(String authorId) {
    _hiddenAuthors.add(authorId);
    final current = state;
    if (current is FeedLoaded) {
      emit(FeedLoaded(_withoutHidden(current.feed)));
    }
  }

  Feed _withoutHidden(Feed feed) => _hiddenAuthors.isEmpty
      ? feed
      : Feed(
          question: feed.question,
          posts: [
            for (final post in feed.posts)
              if (!_hiddenAuthors.contains(post.authorId)) post,
          ],
        );

  void _reportFailure(Result<void> result) {
    if (isClosed) return;
    final current = state;
    if (result case Err<void>(:final failure) when current is FeedLoaded) {
      emit(FeedLoaded(current.feed, actionError: failure.message));
    }
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
