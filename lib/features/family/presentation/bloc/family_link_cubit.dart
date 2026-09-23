import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../matching/domain/entities/match.dart';
import '../../../matching/domain/usecases/get_my_matches.dart';
import '../../../matching/domain/usecases/set_match_visible_to_family.dart';
import '../../domain/usecases/get_or_create_invite_code.dart';

part 'family_link_state.dart';

/// The *single*-side "Aile Bağlantısı" screen (FR-8.3/8.4): shows the
/// invite code and lists this account's matches with an "aileme göster"
/// switch each. Unlike the guardian side, this legitimately reaches into
/// `matching`'s use cases — it's a single user acting on their own
/// matches — so this presentation-layer cubit imports both features.
class FamilyLinkCubit extends Cubit<FamilyLinkState> {
  FamilyLinkCubit({
    required GetOrCreateInviteCode getOrCreateInviteCode,
    required GetMyMatches getMyMatches,
    required SetMatchVisibleToFamily setMatchVisibleToFamily,
  }) : _getOrCreateInviteCode = getOrCreateInviteCode,
       _getMyMatches = getMyMatches,
       _setMatchVisibleToFamily = setMatchVisibleToFamily,
       super(const FamilyLinkLoading());

  final GetOrCreateInviteCode _getOrCreateInviteCode;
  final GetMyMatches _getMyMatches;
  final SetMatchVisibleToFamily _setMatchVisibleToFamily;

  Future<void> load(String singleUserId) async {
    emit(const FamilyLinkLoading());
    final codeResult = await _getOrCreateInviteCode(singleUserId);
    final matchesResult = await _getMyMatches(const NoParams());

    switch ((codeResult, matchesResult)) {
      case (
        Ok<String>(value: final code),
        Ok<List<Match>>(value: final matches),
      ):
        emit(FamilyLinkLoaded(inviteCode: code, matches: matches));
      case (Err<String>(:final failure), _):
        emit(FamilyLinkError(failure.message));
      case (_, Err<List<Match>>(:final failure)):
        emit(FamilyLinkError(failure.message));
    }
  }

  Future<void> setVisible({
    required String matchId,
    required bool visible,
  }) async {
    final current = state;
    if (current is! FamilyLinkLoaded) return;

    // Optimistic update; roll back if the repository rejects it.
    final optimistic = current.matches
        .map((m) => m.id == matchId ? m.copyWith(visibleToFamily: visible) : m)
        .toList();
    emit(FamilyLinkLoaded(inviteCode: current.inviteCode, matches: optimistic));

    final result = await _setMatchVisibleToFamily(
      SetMatchVisibleToFamilyParams(matchId: matchId, visible: visible),
    );
    if (result is Err<void>) {
      emit(current);
    }
  }
}
