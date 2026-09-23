import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this.remoteDataSource});

  final ProfileRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> saveProfile(Profile profile) async {
    try {
      await remoteDataSource.save(ProfileModel.fromEntity(profile));
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Profil kaydedilemedi.'));
    }
  }

  @override
  Future<Result<bool>> hasProfile(String userId) async {
    try {
      return Ok(await remoteDataSource.hasProfile(userId));
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Profil kontrol edilemedi.'));
    }
  }
}
