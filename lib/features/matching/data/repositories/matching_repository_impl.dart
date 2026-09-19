import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import '../../domain/repositories/matching_repository.dart';
import '../datasources/matching_remote_data_source.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  const MatchingRepositoryImpl({required this.remoteDataSource});

  final MatchingRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Candidate>>> getCandidates(CandidateFilter filter) =>
      _guard(() => remoteDataSource.getCandidates(filter), 'Adaylar yüklenemedi.');

  @override
  Future<Result<SwipeOutcome>> swipe({required Candidate candidate, required SwipeAction action}) =>
      _guard(() => remoteDataSource.swipe(candidate: candidate, action: action), 'Bir sorun oluştu.');

  @override
  Future<Result<List<Match>>> getMyMatches() =>
      _guard(() => remoteDataSource.getMyMatches(), 'Eşleşmeler yüklenemedi.');

  @override
  Future<Result<void>> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) => _guard(
    () => remoteDataSource.setMatchVisibleToFamily(matchId: matchId, visible: visible),
    'Bir sorun oluştu.',
  );

  Future<Result<T>> _guard<T>(Future<T> Function() action, String fallbackMessage) async {
    try {
      return Ok(await action());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? fallbackMessage));
    }
  }
}
