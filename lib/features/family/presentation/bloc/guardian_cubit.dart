import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/family_visible_match.dart';
import '../../domain/entities/relationship.dart';
import '../../domain/usecases/get_visible_matches.dart';
import '../../domain/usecases/link_guardian.dart';

part 'guardian_state.dart';

/// The guardian-side flow (FR-8.2/8.3/8.5): link with an invite code, then
/// view the read-only match list. Provided at the app root — same
/// reasoning as `AuthCubit`: two screens (`/guardian/link` →
/// `/guardian/home`) share this state. By construction, this cubit can
/// only reach the family use cases — never matching or messaging (FR-8.6).
class GuardianCubit extends Cubit<GuardianState> {
  GuardianCubit({
    required LinkGuardian linkGuardian,
    required GetVisibleMatches getVisibleMatches,
  }) : _linkGuardian = linkGuardian,
       _getVisibleMatches = getVisibleMatches,
       super(const GuardianIdle());

  final LinkGuardian _linkGuardian;
  final GetVisibleMatches _getVisibleMatches;

  Future<void> link({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  }) async {
    emit(const GuardianLinking());
    final result = await _linkGuardian(
      LinkGuardianParams(
        guardianUserId: guardianUserId,
        guardianName: guardianName,
        relationship: relationship,
        inviteCode: inviteCode,
      ),
    );
    switch (result) {
      case Ok<void>():
        emit(const GuardianLinked());
      case Err<void>(:final failure):
        emit(GuardianLinkFailed(failure.message));
    }
  }

  Future<void> loadMatches(String guardianUserId) async {
    emit(const GuardianMatchesLoading());
    final result = await _getVisibleMatches(guardianUserId);
    switch (result) {
      case Ok<List<FamilyVisibleMatch>>(:final value):
        emit(GuardianMatchesLoaded(value));
      case Err<List<FamilyVisibleMatch>>(:final failure):
        emit(GuardianMatchesFailed(failure.message));
    }
  }
}
