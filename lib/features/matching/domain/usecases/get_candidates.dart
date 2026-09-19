import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/candidate.dart';
import '../entities/candidate_filter.dart';
import '../repositories/matching_repository.dart';

class GetCandidates implements UseCase<List<Candidate>, CandidateFilter> {
  const GetCandidates(this._repository);
  final MatchingRepository _repository;

  @override
  Future<Result<List<Candidate>>> call(CandidateFilter params) =>
      _repository.getCandidates(params);
}
