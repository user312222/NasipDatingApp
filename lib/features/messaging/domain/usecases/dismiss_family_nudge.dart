import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/messaging_repository.dart';

class DismissFamilyNudge implements UseCase<void, String> {
  const DismissFamilyNudge(this._repository);
  final MessagingRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.dismissFamilyNudge(params);
}
