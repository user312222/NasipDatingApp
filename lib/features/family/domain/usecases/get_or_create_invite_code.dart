import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/family_repository.dart';

/// Param is the single user's own id.
class GetOrCreateInviteCode implements UseCase<String, String> {
  const GetOrCreateInviteCode(this._repository);
  final FamilyRepository _repository;

  @override
  Future<Result<String>> call(String params) =>
      _repository.getOrCreateInviteCode(params);
}
