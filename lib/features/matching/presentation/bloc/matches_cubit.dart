import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
// Presentation-level bridge between the two features (like Discovery
// opening Chat): the list shows each match's latest message, but
// `matching`'s domain stays independent of `messaging`.
import '../../../messaging/domain/entities/chat_message.dart';
import '../../../messaging/domain/usecases/watch_last_messages.dart';
import '../../domain/entities/match.dart';
import '../../domain/usecases/get_my_matches.dart';

sealed class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object?> get props => [];
}

final class MatchesLoading extends MatchesState {
  const MatchesLoading();
}

final class MatchesError extends MatchesState {
  const MatchesError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class MatchesLoaded extends MatchesState {
  const MatchesLoaded(this.matches, {this.previews = const {}});

  final List<Match> matches;

  /// Latest message per match id; a match with no messages yet is absent.
  final Map<String, ChatMessage> previews;

  @override
  List<Object?> get props => [matches, previews];
}

/// Backs the matches list — the only way back into a conversation after
/// the match celebration has been dismissed.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit({
    required GetMyMatches getMyMatches,
    required WatchLastMessages watchLastMessages,
  }) : _getMyMatches = getMyMatches,
       _watchLastMessages = watchLastMessages,
       super(const MatchesLoading());

  final GetMyMatches _getMyMatches;
  final WatchLastMessages _watchLastMessages;
  StreamSubscription<Result<Map<String, ChatMessage>>>? _previewsSub;

  /// Shows the matches straight away (newest first), then keeps message
  /// previews live — a slow or failed preview stream never blocks or
  /// breaks the list itself.
  Future<void> load() async {
    await _previewsSub?.cancel();
    _previewsSub = null;
    emit(const MatchesLoading());
    final result = await _getMyMatches(const NoParams());
    if (isClosed) return;
    switch (result) {
      case Ok<List<Match>>(:final value):
        final sorted = [...value]
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        emit(MatchesLoaded(sorted));
        _watchPreviews(sorted);
      case Err<List<Match>>(:final failure):
        emit(MatchesError(failure.message));
    }
  }

  /// Each emission re-orders the list by most recent activity. A stream
  /// error leaves the list as it was.
  void _watchPreviews(List<Match> matches) {
    if (matches.isEmpty) return;
    _previewsSub =
        _watchLastMessages(
          WatchLastMessagesParams([for (final m in matches) m.id]),
        ).listen((result) {
          if (result case Ok<Map<String, ChatMessage>>(:final value)) {
            DateTime activity(Match m) => value[m.id]?.sentAt ?? m.matchedAt;
            final ordered = [...matches]
              ..sort((a, b) => activity(b).compareTo(activity(a)));
            emit(MatchesLoaded(ordered, previews: value));
          }
        });
  }

  @override
  Future<void> close() {
    unawaited(_previewsSub?.cancel());
    return super.close();
  }
}
