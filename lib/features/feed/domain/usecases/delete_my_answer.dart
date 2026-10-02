import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class DeleteMyAnswer implements UseCase<void, NoParams> {
  const DeleteMyAnswer(this._repository);
  final FeedRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.deleteMyAnswer();
}
