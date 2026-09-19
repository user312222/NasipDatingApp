part of 'profile_cubit.dart';

/// Everything the wizard has collected so far. Lives entirely in the
/// presentation layer — photo bytes are a UI concern, not a domain one;
/// [ProfileCubit.submit] converts this into a real [Profile] entity only
/// at the very end.
class ProfileDraft extends Equatable {
  const ProfileDraft({
    this.photos = const [],
    this.photoVisibility = PhotoVisibility.hiddenUntilIUnlock,
    this.intent,
    this.name = '',
    this.birthDate,
    this.city = '',
    this.educationLevel,
    this.occupation,
    this.religiousPracticeNote,
    this.madhhab,
    this.familyInvolvementOptIn = false,
  });

  final List<Uint8List> photos;

  /// FR-3.2: starts at the most restrictive level; the wizard's privacy
  /// step only ever lets the user open it up, never defaults it open.
  final PhotoVisibility photoVisibility;

  final ProfileIntent? intent;
  final String name;
  final DateTime? birthDate;
  final String city;
  final String? educationLevel;
  final String? occupation;
  final String? religiousPracticeNote;
  final String? madhhab;
  final bool familyInvolvementOptIn;

  bool get hasValidPhotos => photos.isNotEmpty && photos.length <= 6;

  int? get age {
    final b = birthDate;
    if (b == null) return null;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) years--;
    return years;
  }

  bool get hasValidDetails => name.trim().isNotEmpty && city.trim().isNotEmpty && (age ?? 0) >= 18;

  ProfileDraft copyWith({
    List<Uint8List>? photos,
    PhotoVisibility? photoVisibility,
    ProfileIntent? intent,
    String? name,
    DateTime? birthDate,
    String? city,
    String? educationLevel,
    String? occupation,
    String? religiousPracticeNote,
    String? madhhab,
    bool? familyInvolvementOptIn,
  }) {
    return ProfileDraft(
      photos: photos ?? this.photos,
      photoVisibility: photoVisibility ?? this.photoVisibility,
      intent: intent ?? this.intent,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      educationLevel: educationLevel ?? this.educationLevel,
      occupation: occupation ?? this.occupation,
      religiousPracticeNote: religiousPracticeNote ?? this.religiousPracticeNote,
      madhhab: madhhab ?? this.madhhab,
      familyInvolvementOptIn: familyInvolvementOptIn ?? this.familyInvolvementOptIn,
    );
  }

  @override
  List<Object?> get props => [
    photos.length,
    photoVisibility,
    intent,
    name,
    birthDate,
    city,
    educationLevel,
    occupation,
    religiousPracticeNote,
    madhhab,
    familyInvolvementOptIn,
  ];
}
