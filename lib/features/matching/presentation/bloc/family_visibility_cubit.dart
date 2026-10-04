import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/usecases/get_match_visible_to_family.dart';
import '../../domain/usecases/set_match_visible_to_family.dart';

part 'family_visibility_state.dart';

/// The "aileme göster" switch for one match, as shown in the chat (FR-8.4:
/// it can be changed there any time after the match celebration). Loads
/// the current choice, then saves changes optimistically and puts the
/// switch back if the save fails.
class FamilyVisibilityCubit extends Cubit<FamilyVisibilityState> {
  FamilyVisibilityCubit({
    required GetMatchVisibleToFamily getMatchVisibleToFamily,
    required SetMatchVisibleToFamily setMatchVisibleToFamily,
  }) : _getMatchVisibleToFamily = getMatchVisibleToFamily,
       _setMatchVisibleToFamily = setMatchVisibleToFamily,
       super(const FamilyVisibilityLoading());

  final GetMatchVisibleToFamily _getMatchVisibleToFamily;
  final SetMatchVisibleToFamily _setMatchVisibleToFamily;

  String? _matchId;

  Future<void> load(String matchId) async {
    _matchId = matchId;
    final result = await _getMatchVisibleToFamily(matchId);
    if (isClosed) return;
    switch (result) {
      case Ok<bool>(:final value):
        emit(FamilyVisibilityReady(visible: value));
      case Err<bool>():
        emit(const FamilyVisibilityUnavailable());
    }
  }

  Future<void> setVisible(bool visible) async {
    final current = state;
    final matchId = _matchId;
    if (current is! FamilyVisibilityReady ||
        current.isSaving ||
        matchId == null) {
      return;
    }

    emit(FamilyVisibilityReady(visible: visible, isSaving: true));
    final result = await _setMatchVisibleToFamily(
      SetMatchVisibleToFamilyParams(matchId: matchId, visible: visible),
    );
    if (isClosed) return;
    emit(
      result is Ok<void>
          ? FamilyVisibilityReady(visible: visible)
          : FamilyVisibilityReady(visible: current.visible, saveFailed: true),
    );
  }
}
