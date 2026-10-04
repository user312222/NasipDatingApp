import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/family_repository.dart';

/// Param is the guardian's own user id. Null when the linked account has
/// no public profile (yet, or any more).
class GetLinkedSingleName implements UseCase<String?, String> {
  const GetLinkedSingleName(this._repository);
  final FamilyRepository _repository;

  @override
  Future<Result<String?>> call(String params) =>
      _repository.getLinkedSingleName(params);
}
