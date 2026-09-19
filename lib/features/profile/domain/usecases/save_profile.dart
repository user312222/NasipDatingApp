import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class SaveProfile implements UseCase<void, Profile> {
  const SaveProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<void>> call(Profile params) => _repository.saveProfile(params);
}
