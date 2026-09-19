import '../../../../core/result/result.dart';
import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Result<void>> saveProfile(Profile profile);
}
