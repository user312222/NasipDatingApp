import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/candidate.dart';
import '../entities/swipe_outcome.dart';
import '../repositories/matching_repository.dart';

class SwipeCandidateParams extends Equatable {
  const SwipeCandidateParams({required this.candidate, required this.action});
  final Candidate candidate;
  final SwipeAction action;

  @override
  List<Object?> get props => [candidate, action];
}

class SwipeCandidate implements UseCase<SwipeOutcome, SwipeCandidateParams> {
  const SwipeCandidate(this._repository);
  final MatchingRepository _repository;

  @override
  Future<Result<SwipeOutcome>> call(SwipeCandidateParams params) =>
      _repository.swipe(candidate: params.candidate, action: params.action);
}
