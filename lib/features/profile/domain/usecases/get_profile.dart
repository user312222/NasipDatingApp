import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfileParams extends Equatable {
  const GetProfileParams(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// See `ProfileRepository.getProfile`.
class GetProfile implements UseCase<Profile?, GetProfileParams> {
  const GetProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<Profile?>> call(GetProfileParams params) =>
      _repository.getProfile(params.userId);
}
