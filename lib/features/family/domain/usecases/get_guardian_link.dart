import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/guardian_link.dart';
import '../repositories/family_repository.dart';

/// Param is the guardian's own user id. Null when not linked yet.
class GetGuardianLink implements UseCase<GuardianLink?, String> {
  const GetGuardianLink(this._repository);
  final FamilyRepository _repository;

  @override
  Future<Result<GuardianLink?>> call(String params) =>
      _repository.getGuardianLink(params);
}
