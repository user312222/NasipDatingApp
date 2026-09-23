import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl({required this.remoteDataSource});

  final AccountRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> deleteAccount(String userId) async {
    try {
      await remoteDataSource.deleteAccount(userId);
      return const Ok(null);
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Hesap silinemedi.'));
    }
  }
}
