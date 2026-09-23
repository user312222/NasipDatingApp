import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/account_repository.dart';

class DeleteAccount implements UseCase<void, String> {
  const DeleteAccount(this._repository);
  final AccountRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.deleteAccount(params);
}
