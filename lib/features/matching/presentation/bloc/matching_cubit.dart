import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import '../../domain/usecases/get_candidates.dart';
import '../../domain/usecases/set_match_visible_to_family.dart';
import '../../domain/usecases/swipe_candidate.dart';

part 'matching_state.dart';

class MatchingCubit extends Cubit<MatchingState> {
  MatchingCubit({
    required GetCandidates getCandidates,
    required SwipeCandidate swipeCandidate,
    required SetMatchVisibleToFamily setMatchVisibleToFamily,
  }) : _getCandidates = getCandidates,
       _swipeCandidate = swipeCandidate,
       _setMatchVisibleToFamily = setMatchVisibleToFamily,
       super(const MatchingLoading());

  final GetCandidates _getCandidates;
  final SwipeCandidate _swipeCandidate;
  final SetMatchVisibleToFamily _setMatchVisibleToFamily;

  Future<void> loadCandidates({
    CandidateFilter filter = CandidateFilter.empty,
  }) async {
    emit(const MatchingLoading());
    final result = await _getCandidates(filter);
    switch (result) {
      case Ok<List<Candidate>>(:final value):
        emit(MatchingLoaded(candidates: value, filter: filter));
      case Err<List<Candidate>>(:final failure):
        emit(MatchingError(failure.message));
    }
  }

  /// FR-6.2: drops a just-blocked candidate from the in-memory feed so the
  /// next card slides into place without a refetch resetting progress.
  void removeCandidate(String candidateId) {
    final current = state;
    if (current is! MatchingLoaded) return;
    emit(
      current.copyWith(
        candidates: current.candidates
            .where((c) => c.id != candidateId)
            .toList(),
      ),
    );
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

  /// FR-8.4: the "aileme göster" switch on the match celebration. Returns
  /// whether the choice was saved. Nothing is emitted - the dialog owns its
  /// switch, and `justMatched` is a one-shot the feed has already moved
  /// past.
  Future<bool> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) async {
    final result = await _setMatchVisibleToFamily(
      SetMatchVisibleToFamilyParams(matchId: matchId, visible: visible),
    );
    return result is Ok<void>;
  }
}
