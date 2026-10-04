import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remoteDataSource});

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Result<void>> checkInviteCode(String code) =>
      _guard(() => remoteDataSource.checkInviteCode(code));

  @override
  Future<Result<void>> requestOtp(String phone) =>
      _guard(() => remoteDataSource.requestOtp(phone));

  @override
  Future<Result<AuthUser>> verifyOtp({
    required String phone,
    required String code,
    required AccountType accountType,
  }) => _guard(
    () => remoteDataSource.verifyOtp(
      phone: phone,
      code: code,
      accountType: accountType,
    ),
  );

  @override
  Future<Result<AuthUser?>> verifySignInOtp({
    required String phone,
    required String code,
  }) =>
      _guard(() => remoteDataSource.verifySignInOtp(phone: phone, code: code));

  @override
  Future<Result<AuthUser>> submitSelfieVerification(AuthUser user) =>
      _guard(() => remoteDataSource.submitSelfieVerification(user));

  @override
  Future<Result<AuthUser?>> getCurrentSession() =>
      _guard(() => remoteDataSource.getCurrentSession());

  @override
  Future<Result<void>> logOut() => _guard(() => remoteDataSource.logOut());

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message ?? 'Bir sorun oluştu.'));
    }
  }
}
