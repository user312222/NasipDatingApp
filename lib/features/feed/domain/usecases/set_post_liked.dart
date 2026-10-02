import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/feed_repository.dart';

class SetPostLikedParams extends Equatable {
  const SetPostLikedParams({required this.postId, required this.liked});
  final String postId;
  final bool liked;

  @override
  List<Object?> get props => [postId, liked];
}

class SetPostLiked implements UseCase<void, SetPostLikedParams> {
  const SetPostLiked(this._repository);
  final FeedRepository _repository;

  @override
  Future<Result<void>> call(SetPostLikedParams params) =>
      _repository.setLiked(postId: params.postId, liked: params.liked);
}
