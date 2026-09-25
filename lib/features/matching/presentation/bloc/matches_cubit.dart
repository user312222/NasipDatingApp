import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
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
  const MatchesLoaded(this.matches);
  final List<Match> matches;

  @override
  List<Object?> get props => [matches];
}

/// Backs the matches list — the only way back into a conversation after
/// the match celebration has been dismissed.
class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit({required GetMyMatches getMyMatches})
    : _getMyMatches = getMyMatches,
      super(const MatchesLoading());

  final GetMyMatches _getMyMatches;

  Future<void> load() async {
    emit(const MatchesLoading());
    final result = await _getMyMatches(const NoParams());
    switch (result) {
      case Ok<List<Match>>(:final value):
        final sorted = [...value]
          ..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        emit(MatchesLoaded(sorted));
      case Err<List<Match>>(:final failure):
        emit(MatchesError(failure.message));
    }
  }
}
