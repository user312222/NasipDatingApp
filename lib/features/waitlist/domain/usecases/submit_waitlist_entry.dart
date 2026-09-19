import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/waitlist_entry.dart';
import '../repositories/waitlist_repository.dart';

class SubmitWaitlistEntry implements UseCase<void, WaitlistEntry> {
  const SubmitWaitlistEntry(this._repository);

  final WaitlistRepository _repository;

  @override
  Future<Result<void>> call(WaitlistEntry params) => _repository.submit(params);
}
