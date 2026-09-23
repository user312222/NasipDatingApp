import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/consent_repository.dart';

class RecordConsentParams extends Equatable {
  const RecordConsentParams({
    required this.userId,
    required this.consentVersion,
  });

  final String userId;
  final String consentVersion;

  @override
  List<Object?> get props => [userId, consentVersion];
}

class RecordConsent implements UseCase<void, RecordConsentParams> {
  const RecordConsent(this._repository);
  final ConsentRepository _repository;

  @override
  Future<Result<void>> call(RecordConsentParams params) =>
      _repository.recordConsent(
        userId: params.userId,
        consentVersion: params.consentVersion,
      );
}
