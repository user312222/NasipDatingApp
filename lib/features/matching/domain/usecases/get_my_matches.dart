import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/match.dart';
import '../repositories/matching_repository.dart';

class GetMyMatches implements UseCase<List<Match>, NoParams> {
  const GetMyMatches(this._repository);
  final MatchingRepository _repository;

  @override
  Future<Result<List<Match>>> call(NoParams params) => _repository.getMyMatches();
}
