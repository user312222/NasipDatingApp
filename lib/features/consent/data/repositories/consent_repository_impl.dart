import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/consent_repository.dart';
import '../datasources/consent_remote_data_source.dart';

class ConsentRepositoryImpl implements ConsentRepository {
  const ConsentRepositoryImpl({required this.remoteDataSource});

  final ConsentRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> recordConsent({
    required String userId,
    required String consentVersion,
  }) async {
    try {
      await remoteDataSource.recordConsent(
        userId: userId,
        consentVersion: consentVersion,
      );
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Rıza kaydı tutulamadı.'));
    }
  }
}
