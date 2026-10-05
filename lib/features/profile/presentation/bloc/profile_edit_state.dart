part of 'profile_edit_cubit.dart';

sealed class ProfileEditState extends Equatable {
  const ProfileEditState();

  @override
  List<Object?> get props => [];
}

final class ProfileEditLoading extends ProfileEditState {
  const ProfileEditLoading();
}

/// The profile could not be read, or there is none yet.
final class ProfileEditUnavailable extends ProfileEditState {
  const ProfileEditUnavailable(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

final class ProfileEditReady extends ProfileEditState {
  const ProfileEditReady(this.profile, {this.saving = false, this.error});

  /// The profile as stored - what the form started from, not what is
  /// currently typed into it.
  final Profile profile;
  final bool saving;

  /// Why the last save did not go through; shown next to the save button.
  final String? error;

  @override
  List<Object?> get props => [profile, saving, error];
}

final class ProfileEditSaved extends ProfileEditState {
  const ProfileEditSaved(this.profile, {required this.changed});
  final Profile profile;

  /// False when "Kaydet" was pressed with nothing changed: nothing was
  /// written, so there is nothing to announce.
  final bool changed;

  @override
  List<Object?> get props => [profile, changed];
}
