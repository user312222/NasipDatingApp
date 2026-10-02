import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class SubmitAnswer implements UseCase<void, String> {
  const SubmitAnswer(this._repository);
  final FeedRepository _repository;

  @override
  Future<Result<void>> call(String params) => _repository.submitAnswer(params);
}
