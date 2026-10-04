import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class VerifySignInOtpParams extends Equatable {
  const VerifySignInOtpParams({required this.phone, required this.code});
  final String phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

/// The "Hesabım var" door: verifies the code for a number that should
/// already have an account. `Ok(null)` means there is none.
class VerifySignInOtp implements UseCase<AuthUser?, VerifySignInOtpParams> {
  const VerifySignInOtp(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser?>> call(VerifySignInOtpParams params) =>
      _repository.verifySignInOtp(phone: params.phone, code: params.code);
}
