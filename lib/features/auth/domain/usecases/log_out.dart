import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// See `AuthRepository.logOut`.
class LogOut implements UseCase<void, NoParams> {
  const LogOut(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.logOut();
}
