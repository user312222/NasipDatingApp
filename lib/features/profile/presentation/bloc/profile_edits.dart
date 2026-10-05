part of 'profile_edit_cubit.dart';

/// What the edit screen can change. Everything else about a profile - the
/// account it belongs to, the birth date, the photos - is carried over from
/// the stored one by [applyTo], so nothing typed on the screen can touch it.
///
/// The birth date is fixed on purpose: age is one of the few things a match
/// relies on, and it should not move after people have met.
class ProfileEdits extends Equatable {
  const ProfileEdits({
    required this.name,
    required this.city,
    required this.intent,
    required this.photoVisibility,
    required this.familyInvolvementOptIn,
    this.educationLevel,
    this.occupation,
    this.religiousPracticeNote,
    this.madhhab,
  });

  /// The form's starting point: the stored profile, unchanged.
  factory ProfileEdits.of(Profile profile) => ProfileEdits(
    name: profile.name,
    city: profile.city,
    intent: profile.intent,
    photoVisibility: profile.photoVisibility,
    familyInvolvementOptIn: profile.familyInvolvementOptIn,
    educationLevel: profile.educationLevel,
    occupation: profile.occupation,
    religiousPracticeNote: profile.religiousPracticeNote,
    madhhab: profile.madhhab,
  );

  final String name;
  final String city;
  final ProfileIntent intent;
  final PhotoVisibility photoVisibility;
  final bool familyInvolvementOptIn;
  final String? educationLevel;
  final String? occupation;
  final String? religiousPracticeNote;
  final String? madhhab;

  /// [stored] with these edits applied: text trimmed, and an optional
  /// field left blank removed rather than saved as an empty string.
  Profile applyTo(Profile stored) => Profile(
    userId: stored.userId,
    birthDate: stored.birthDate,
    photoRefs: stored.photoRefs,
    name: name.trim(),
    city: city.trim(),
    intent: intent,
    photoVisibility: photoVisibility,
    familyInvolvementOptIn: familyInvolvementOptIn,
    educationLevel: _blankToNull(educationLevel),
    occupation: _blankToNull(occupation),
    religiousPracticeNote: _blankToNull(religiousPracticeNote),
    madhhab: _blankToNull(madhhab),
  );

  /// Whether saving these edits would change anything in [stored].
  ///
  /// Compares only what the screen can edit, tidied the same way on both
  /// sides - not the two profiles as objects: the stored one arrives as the
  /// data layer's own subclass, which never equals a plain [Profile], and
  /// an old document may hold an empty string where a new one holds nothing.
  bool changes(Profile stored) =>
      ProfileEdits.of(applyTo(stored)) !=
      ProfileEdits.of(ProfileEdits.of(stored).applyTo(stored));

  /// KVKK m.6: religious data needs its own explicit consent. That was
  /// given for whatever is already stored; it is needed again only when
  /// these edits add or reword it. Clearing a field, leaving it alone, or
  /// choosing [madhhabNoAnswer] discloses nothing new.
  bool needsSensitiveConsent(Profile stored) {
    final updated = applyTo(stored);
    final note = updated.religiousPracticeNote;
    final madhhab = updated.madhhab;
    return (note != null && note != stored.religiousPracticeNote) ||
        (madhhab != null &&
            madhhab != madhhabNoAnswer &&
            madhhab != stored.madhhab);
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [
    name,
    city,
    intent,
    photoVisibility,
    familyInvolvementOptIn,
    educationLevel,
    occupation,
    religiousPracticeNote,
    madhhab,
  ];
}
