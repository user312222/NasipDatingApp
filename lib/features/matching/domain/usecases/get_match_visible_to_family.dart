import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/matching_repository.dart';

/// FR-8.4: whether one match is currently marked "aileme göster" — the
/// chat screen's switch starts from this.
class GetMatchVisibleToFamily implements UseCase<bool, String> {
  const GetMatchVisibleToFamily(this._repository);
  final MatchingRepository _repository;

  @override
  Future<Result<bool>> call(String matchId) =>
      _repository.isMatchVisibleToFamily(matchId);
}
