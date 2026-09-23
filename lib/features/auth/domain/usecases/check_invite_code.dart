import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class CheckInviteCode implements UseCase<void, String> {
  const CheckInviteCode(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.checkInviteCode(params);
}
