import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/matching_repository.dart';

class SetMatchVisibleToFamilyParams extends Equatable {
  const SetMatchVisibleToFamilyParams({
    required this.matchId,
    required this.visible,
  });
  final String matchId;
  final bool visible;

  @override
  List<Object?> get props => [matchId, visible];
}

class SetMatchVisibleToFamily
    implements UseCase<void, SetMatchVisibleToFamilyParams> {
  const SetMatchVisibleToFamily(this._repository);
  final MatchingRepository _repository;

  @override
  Future<Result<void>> call(SetMatchVisibleToFamilyParams params) =>
      _repository.setMatchVisibleToFamily(
        matchId: params.matchId,
        visible: params.visible,
      );
}
