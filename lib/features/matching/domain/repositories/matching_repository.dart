import '../../../../core/result/result.dart';
import '../entities/candidate.dart';
import '../entities/candidate_filter.dart';
import '../entities/match.dart';
import '../entities/swipe_outcome.dart';

abstract interface class MatchingRepository {
  /// FR-4.1.
  Future<Result<List<Candidate>>> getCandidates(CandidateFilter filter);

  /// FR-4.2/FR-4.3: a `like` beyond the daily cap fails with a
  /// [Failure] the UI can show as-is — see `MockMatchingRemoteDataSource`.
  Future<Result<SwipeOutcome>> swipe({required Candidate candidate, required SwipeAction action});

  /// FR-8.4: all of this account's matches, for the "aileme göster"
  /// toggle list — see `features/family` for the read-only side of this.
  Future<Result<List<Match>>> getMyMatches();

  /// FR-8.4.
  Future<Result<void>> setMatchVisibleToFamily({required String matchId, required bool visible});
}
