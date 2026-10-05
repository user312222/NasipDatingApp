import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/guardian_link.dart';
import '../../domain/usecases/get_guardian_link.dart';

/// Whether - and to whom - the guardian is linked right now. The link
/// screen needs it to know if it is making a first link or replacing one,
/// and the settings card to say whose account it is. One per screen that
/// asks (each provides its own).
class CurrentLinkCubit extends Cubit<CurrentLinkState> {
  CurrentLinkCubit({required GetGuardianLink getGuardianLink})
    : _getGuardianLink = getGuardianLink,
      super(const CurrentLinkLoading());

  final GetGuardianLink _getGuardianLink;

  Future<void> load(String guardianUserId) async {
    final result = await _getGuardianLink(guardianUserId);
    if (isClosed) return;
    emit(switch (result) {
      Ok<GuardianLink?>(value: final link?) => CurrentLinkFound(link),
      // A failed read is treated like "not linked": the plain link form
      // still works either way, and `firestore.rules` decides on the save.
      Ok<GuardianLink?>() || Err<GuardianLink?>() => const CurrentLinkNone(),
    });
  }
}

sealed class CurrentLinkState extends Equatable {
  const CurrentLinkState();

  @override
  List<Object?> get props => [];
}

final class CurrentLinkLoading extends CurrentLinkState {
  const CurrentLinkLoading();
}

final class CurrentLinkNone extends CurrentLinkState {
  const CurrentLinkNone();
}

final class CurrentLinkFound extends CurrentLinkState {
  const CurrentLinkFound(this.link);
  final GuardianLink link;

  @override
  List<Object?> get props => [link];
}
