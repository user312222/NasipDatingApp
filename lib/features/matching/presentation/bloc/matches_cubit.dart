import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
// Presentation-level bridge between the two features (like Discovery
// opening Chat): the list shows each match's latest message, but
// `matching`'s domain stays independent of `messaging`.
import '../../../messaging/domain/entities/chat_message.dart';
import '../../../messaging/domain/usecases/get_last_messages.dart';
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
    required GetLastMessages getLastMessages,
  }) : _getMyMatches = getMyMatches,
       _getLastMessages = getLastMessages,
       super(const MatchesLoading());

  final GetMyMatches _getMyMatches;
  final GetLastMessages _getLastMessages;

  /// Shows the matches straight away (newest first), then fills in message
  /// previews once they arrive — a slow or failed preview fetch never
  /// blocks or breaks the list itself.
  Future<void> load() async {
    emit(const MatchesLoading());
    final result = await _getMyMatches(const NoParams());
    switch (result) {
      case Ok<List<Match>>(:final value):
        final sorted = [...value]
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        emit(MatchesLoaded(sorted));
        await refreshPreviews();
      case Err<List<Match>>(:final failure):
        emit(MatchesError(failure.message));
    }
  }

  /// Re-fetches previews silently (no loading state) and re-orders by most
  /// recent activity — used after returning from a chat.
  Future<void> refreshPreviews() async {
    final current = state;
    if (current is! MatchesLoaded || current.matches.isEmpty) return;

    final result = await _getLastMessages(
      GetLastMessagesParams([for (final m in current.matches) m.id]),
    );
    if (isClosed) return;
    if (result case Ok<Map<String, ChatMessage>>(:final value)) {
      DateTime activity(Match m) => value[m.id]?.sentAt ?? m.matchedAt;
      final ordered = [...current.matches]
        ..sort((a, b) => activity(b).compareTo(activity(a)));
      emit(MatchesLoaded(ordered, previews: value));
    }
  }
}
