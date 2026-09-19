import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import '../../domain/usecases/get_candidates.dart';
import '../../domain/usecases/swipe_candidate.dart';

part 'matching_state.dart';

class MatchingCubit extends Cubit<MatchingState> {
  MatchingCubit({required GetCandidates getCandidates, required SwipeCandidate swipeCandidate})
    : _getCandidates = getCandidates,
      _swipeCandidate = swipeCandidate,
      super(const MatchingLoading());

  final GetCandidates _getCandidates;
  final SwipeCandidate _swipeCandidate;

  Future<void> loadCandidates({CandidateFilter filter = CandidateFilter.empty}) async {
    emit(const MatchingLoading());
    final result = await _getCandidates(filter);
    switch (result) {
      case Ok<List<Candidate>>(:final value):
        emit(MatchingLoaded(candidates: value, filter: filter));
      case Err<List<Candidate>>(:final failure):
        emit(MatchingError(failure.message));
    }
  }

  Future<void> swipe(SwipeAction action) async {
    final current = state;
    if (current is! MatchingLoaded || current.current == null) return;
    final candidate = current.current!;

    emit(current.copyWith(isSwiping: true));
    final result = await _swipeCandidate(
      SwipeCandidateParams(candidate: candidate, action: action),
    );
    switch (result) {
      case Ok<SwipeOutcome>(:final value):
        emit(
          current.copyWith(
            currentIndex: current.currentIndex + 1,
            justMatched: value.matched ? value.match : null,
          ),
        );
      case Err<SwipeOutcome>(:final failure):
        emit(current.copyWith(swipeError: failure.message));
    }
  }
}
