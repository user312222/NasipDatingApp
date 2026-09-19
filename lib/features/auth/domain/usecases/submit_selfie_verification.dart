import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SubmitSelfieVerification implements UseCase<AuthUser, AuthUser> {
  const SubmitSelfieVerification(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(AuthUser params) =>
      _repository.submitSelfieVerification(params);
}
