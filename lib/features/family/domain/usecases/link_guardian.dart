import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/relationship.dart';
import '../repositories/family_repository.dart';

class LinkGuardianParams extends Equatable {
  const LinkGuardianParams({
    required this.guardianUserId,
    required this.guardianName,
    required this.relationship,
    required this.inviteCode,
  });

  final String guardianUserId;
  final String guardianName;
  final Relationship relationship;
  final String inviteCode;

  @override
  List<Object?> get props => [
    guardianUserId,
    guardianName,
    relationship,
    inviteCode,
  ];
}

class LinkGuardian implements UseCase<void, LinkGuardianParams> {
  const LinkGuardian(this._repository);
  final FamilyRepository _repository;

  @override
  Future<Result<void>> call(LinkGuardianParams params) =>
      _repository.linkGuardian(
        guardianUserId: params.guardianUserId,
        guardianName: params.guardianName,
        relationship: params.relationship,
        inviteCode: params.inviteCode,
      );
}
