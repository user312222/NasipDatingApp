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
import '../../../messaging/domain/usecases/watch_read_times.dart';
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
  const MatchesLoaded(this.matches, {this.previews = const {}, this.readTimes});

  final List<Match> matches;

  /// Latest message per match id; a match with no messages yet is absent.
  final Map<String, ChatMessage> previews;

  /// When the current user last opened each match (absent = never). Null
  /// until the first read has loaded, so nothing flashes "unread" while
  /// it's still on its way.
  final Map<String, DateTime>? readTimes;

  /// Unread = the other party sent the latest message and it's newer than
  /// the last time this user opened the conversation.
  bool isUnread(String matchId) {
    final times = readTimes;
    final last = previews[matchId];
    if (times == null || last == null || last.sender != MessageSender.them) {
      return false;
    }
    final readAt = times[matchId];
    return readAt == null || last.sentAt.isAfter(readAt);
  }

  @override
  List<Object?> get props => [matches, previews, readTimes];
}

/// Backs the matches list - the only way back into a conversation after
/// the match celebration has been dismissed.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit({
    required GetMyMatches getMyMatches,
    required WatchLastMessages watchLastMessages,
    required WatchReadTimes watchReadTimes,
  }) : _getMyMatches = getMyMatches,
       _watchLastMessages = watchLastMessages,
       _watchReadTimes = watchReadTimes,
       super(const MatchesLoading());

  final GetMyMatches _getMyMatches;
  final WatchLastMessages _watchLastMessages;
  final WatchReadTimes _watchReadTimes;
  StreamSubscription<Result<Map<String, ChatMessage>>>? _previewsSub;
  StreamSubscription<Result<Map<String, DateTime>>>? _readTimesSub;

  List<Match> _matches = const [];
  Map<String, ChatMessage> _previews = const {};
  Map<String, DateTime>? _readTimes;

  /// Shows the matches straight away (newest first), then keeps message
  /// previews and unread state live - a slow or failed stream never blocks
  /// or breaks the list itself.
  Future<void> load() async {
    await _cancelSubscriptions();
    emit(const MatchesLoading());
    final result = await _getMyMatches(const NoParams());
    if (isClosed) return;
    switch (result) {
      case Ok<List<Match>>(:final value):
        _matches = [...value]
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        _previews = const {};
        _readTimes = null;
        _publish();
        if (_matches.isEmpty) return;
        _previewsSub =
            _watchLastMessages(
              WatchLastMessagesParams([for (final m in _matches) m.id]),
            ).listen((result) {
              if (result case Ok<Map<String, ChatMessage>>(:final value)) {
                _previews = value;
                _publish();
              }
            });
        _readTimesSub = _watchReadTimes().listen((result) {
          if (result case Ok<Map<String, DateTime>>(:final value)) {
            _readTimes = value;
            _publish();
          }
        });
      case Err<List<Match>>(:final failure):
        emit(MatchesError(failure.message));
    }
  }

  /// Orders by most recent activity; a stream error leaves the list as it
  /// was.
  void _publish() {
    if (isClosed) return;
    DateTime activity(Match m) => _previews[m.id]?.sentAt ?? m.matchedAt;
    final ordered = [..._matches]
      ..sort((a, b) => activity(b).compareTo(activity(a)));
    emit(MatchesLoaded(ordered, previews: _previews, readTimes: _readTimes));
  }

  /// Cancels both at once - awaiting one before starting the other left
  /// the second listener alive long enough to emit into a closed cubit.
  Future<void> _cancelSubscriptions() async {
    final pending = [_previewsSub?.cancel(), _readTimesSub?.cancel()];
    _previewsSub = null;
    _readTimesSub = null;
    await Future.wait(pending.whereType<Future<void>>());
  }

  @override
  Future<void> close() {
    unawaited(_cancelSubscriptions());
    return super.close();
  }
}
