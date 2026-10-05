import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/save_profile.dart';

part 'profile_edit_state.dart';
part 'profile_edits.dart';

/// Owns the "Profili düzenle" screen: loads the stored profile once, then
/// saves the whole profile again with the [ProfileEdits] applied. One per
/// visit (the screen provides it), unlike the wizard's `ProfileCubit`,
/// which lives above the router.
class ProfileEditCubit extends Cubit<ProfileEditState> {
  ProfileEditCubit({
    required GetProfile getProfile,
    required SaveProfile saveProfile,
  }) : _getProfile = getProfile,
       _saveProfile = saveProfile,
       super(const ProfileEditLoading());

  final GetProfile _getProfile;
  final SaveProfile _saveProfile;

  Future<void> load(String userId) async {
    emit(const ProfileEditLoading());
    final result = await _getProfile(GetProfileParams(userId));
    if (isClosed) return;
    switch (result) {
      case Ok<Profile?>(value: final profile?):
        emit(ProfileEditReady(profile));
      case Ok<Profile?>():
        emit(const ProfileEditUnavailable('Henüz bir profilin yok.'));
      case Err<Profile?>(:final failure):
        emit(ProfileEditUnavailable(failure.message));
    }
  }

  /// [sensitiveDataConsent] is the KVKK m.6 box on the screen; it only
  /// matters when [ProfileEdits.needsSensitiveConsent] says so.
  Future<void> save(
    ProfileEdits edits, {
    bool sensitiveDataConsent = false,
  }) async {
    final current = state;
    if (current is! ProfileEditReady || current.saving) return;
    final stored = current.profile;
    final updated = edits.applyTo(stored);

    String? problem;
    if (updated.name.isEmpty || updated.city.isEmpty) {
      problem = 'Ad ve şehir boş bırakılamaz.';
    } else if (updated.name.length > 60) {
      problem = 'Ad en fazla 60 karakter olabilir.';
    } else if (edits.needsSensitiveConsent(stored) && !sensitiveDataConsent) {
      problem =
          'Dini pratik/mezhep bilgini paylaşmak için onayı işaretlemelisin '
          '— ya da bu alanları boş bırakabilirsin.';
    }
    if (problem != null) {
      emit(ProfileEditReady(stored, error: problem));
      return;
    }

    if (!edits.changes(stored)) {
      emit(ProfileEditSaved(stored, changed: false));
      return;
    }

    emit(ProfileEditReady(stored, saving: true));
    final result = await _saveProfile(updated);
    if (isClosed) return;
    switch (result) {
      case Ok<void>():
        emit(ProfileEditSaved(updated, changed: true));
      case Err<void>(:final failure):
        emit(ProfileEditReady(stored, error: failure.message));
    }
  }
}
