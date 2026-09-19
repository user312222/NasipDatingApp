part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  const ProfileState(this.draft);
  final ProfileDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class ProfileEditing extends ProfileState {
  const ProfileEditing(super.draft);
}

final class ProfileSubmitting extends ProfileState {
  const ProfileSubmitting(super.draft);
}

final class ProfileSubmitted extends ProfileState {
  const ProfileSubmitted(super.draft, this.profile);
  final Profile profile;

  @override
  List<Object?> get props => [draft, profile];
}

final class ProfileSubmitError extends ProfileState {
  const ProfileSubmitError(super.draft, this.message);
  final String message;

  @override
  List<Object?> get props => [draft, message];
}
