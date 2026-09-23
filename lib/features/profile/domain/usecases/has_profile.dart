import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/profile_repository.dart';

class HasProfileParams extends Equatable {
  const HasProfileParams(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// See `ProfileRepository.hasProfile`. Called directly from
/// `InviteGateScreen` on session restore — same "screen calls a usecase
/// straight from `sl()`" pattern as `ProfilePhotosScreen`'s
/// `ModeratePhoto`, since this is one-off cross-feature glue, not
/// something `ProfileCubit` itself needs to react to.
class HasProfile implements UseCase<bool, HasProfileParams> {
  const HasProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<bool>> call(HasProfileParams params) =>
      _repository.hasProfile(params.userId);
}
