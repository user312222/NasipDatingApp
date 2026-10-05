import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/save_profile.dart';

part 'profile_draft.dart';
part 'profile_state.dart';

/// Owns the whole FR-2 profile-creation wizard, mirroring how
/// `AuthCubit` owns FR-1 — one cubit provided above all the step screens
/// (see `core/router/app_router.dart`) so the draft survives navigating
/// between them. Unlike `AuthCubit`, nothing hits the network until
/// [submit] — each step just edits the local [ProfileDraft].
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required SaveProfile saveProfile})
    : _saveProfile = saveProfile,
      super(const ProfileEditing(ProfileDraft()));

  final SaveProfile _saveProfile;

  void updatePhotos(List<Uint8List> photos) {
    emit(ProfileEditing(state.draft.copyWith(photos: photos)));
  }

  void updatePhotoVisibility(PhotoVisibility visibility) {
    emit(ProfileEditing(state.draft.copyWith(photoVisibility: visibility)));
  }

  void updateIntent(ProfileIntent intent) {
    emit(ProfileEditing(state.draft.copyWith(intent: intent)));
  }

  void updateDetails({
    required String name,
    required DateTime birthDate,
    required String city,
    String? educationLevel,
    String? occupation,
    String? religiousPracticeNote,
    String? madhhab,
  }) {
    emit(
      ProfileEditing(
        state.draft.copyWith(
          name: name,
          birthDate: birthDate,
          city: city,
          educationLevel: educationLevel,
          occupation: occupation,
          religiousPracticeNote: religiousPracticeNote,
          madhhab: madhhab,
        ),
      ),
    );
  }

  void updateFamilyInvolvement(bool optIn) {
    emit(ProfileEditing(state.draft.copyWith(familyInvolvementOptIn: optIn)));
  }

  Future<void> submit(String userId) async {
    final draft = state.draft;
    final birthDate = draft.birthDate;
    // Each step checks its own part, but on the web a step can be opened
    // by address without the ones before it - so the whole draft is
    // checked once more here, the only place a profile is written.
    if (!draft.hasValidPhotos) {
      emit(ProfileSubmitError(draft, 'En az 1 fotoğraf eklemelisin.'));
      return;
    }
    if (draft.intent == null || birthDate == null || !draft.hasValidDetails) {
      emit(ProfileSubmitError(draft, 'Eksik bilgi var.'));
      return;
    }

    emit(ProfileSubmitting(draft));
    final profile = Profile(
      userId: userId,
      name: draft.name.trim(),
      birthDate: birthDate,
      city: draft.city.trim(),
      intent: draft.intent!,
      photoRefs: List.generate(draft.photos.length, (i) => 'photo_$i.jpg'),
      photoVisibility: draft.photoVisibility,
      familyInvolvementOptIn: draft.familyInvolvementOptIn,
      educationLevel: draft.educationLevel?.trim(),
      occupation: draft.occupation?.trim(),
      religiousPracticeNote: draft.religiousPracticeNote?.trim(),
      madhhab: draft.madhhab?.trim(),
    );

    final result = await _saveProfile(profile);
    switch (result) {
      case Ok<void>():
        emit(ProfileSubmitted(draft, profile));
      case Err<void>(:final failure):
        emit(ProfileSubmitError(draft, failure.message));
    }
  }
}
