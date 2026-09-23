import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/safety_repository.dart';

class BlockUser implements UseCase<void, String> {
  const BlockUser(this._repository);
  final SafetyRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.blockUser(params);
}
