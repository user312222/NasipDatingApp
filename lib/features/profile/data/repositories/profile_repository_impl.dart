import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_local_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.localDataSource});

  final ProfileLocalDataSource localDataSource;

  @override
  Future<Result<void>> saveProfile(Profile profile) async {
    try {
      await localDataSource.save(ProfileModel.fromEntity(profile));
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Profil kaydedilemedi.'));
    }
  }
}
