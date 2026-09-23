import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_reason.dart';
import '../repositories/safety_repository.dart';

class ReportUserParams extends Equatable {
  const ReportUserParams({
    required this.targetUserId,
    required this.reason,
    this.details,
  });
  final String targetUserId;
  final ReportReason reason;
  final String? details;

  @override
  List<Object?> get props => [targetUserId, reason, details];
}

class ReportUser implements UseCase<void, ReportUserParams> {
  const ReportUser(this._repository);
  final SafetyRepository _repository;

  @override
  Future<Result<void>> call(ReportUserParams params) => _repository.reportUser(
    targetUserId: params.targetUserId,
    reason: params.reason,
    details: params.details,
  );
}
