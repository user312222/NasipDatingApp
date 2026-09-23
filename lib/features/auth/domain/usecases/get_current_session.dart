import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// See `AuthRepository.getCurrentSession`.
class GetCurrentSession implements UseCase<AuthUser?, NoParams> {
  const GetCurrentSession(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser?>> call(NoParams params) =>
      _repository.getCurrentSession();
}
