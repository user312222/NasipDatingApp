import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/family_visible_match.dart';
import '../repositories/family_repository.dart';

/// Param is the guardian's own user id.
class GetVisibleMatches implements UseCase<List<FamilyVisibleMatch>, String> {
  const GetVisibleMatches(this._repository);
  final FamilyRepository _repository;

  @override
  Future<Result<List<FamilyVisibleMatch>>> call(String params) =>
      _repository.getVisibleMatches(params);
}
