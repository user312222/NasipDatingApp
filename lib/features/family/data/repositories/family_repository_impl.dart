import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/family_visible_match.dart';
import '../../domain/entities/relationship.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_data_source.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  const FamilyRepositoryImpl({required this.remoteDataSource});

  final FamilyRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> linkGuardian({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  }) => _guard(
    () => remoteDataSource.linkGuardian(
      guardianUserId: guardianUserId,
      guardianName: guardianName,
      relationship: relationship,
      inviteCode: inviteCode,
    ),
  );

  @override
  Future<Result<List<FamilyVisibleMatch>>> getVisibleMatches(
    String guardianUserId,
  ) => _guard(() => remoteDataSource.getVisibleMatches(guardianUserId));

  @override
  Future<Result<String>> getOrCreateInviteCode(String singleUserId) =>
      _guard(() => remoteDataSource.getOrCreateInviteCode(singleUserId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }
}
