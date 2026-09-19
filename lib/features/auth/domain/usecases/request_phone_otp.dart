import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class RequestPhoneOtp implements UseCase<void, String> {
  const RequestPhoneOtp(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.requestOtp(params);
}
