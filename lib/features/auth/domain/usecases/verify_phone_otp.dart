import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpParams extends Equatable {
  const VerifyPhoneOtpParams({required this.phone, required this.code});
  final String phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

class VerifyPhoneOtp implements UseCase<AuthUser, VerifyPhoneOtpParams> {
  const VerifyPhoneOtp(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(VerifyPhoneOtpParams params) =>
      _repository.verifyOtp(phone: params.phone, code: params.code);
}
