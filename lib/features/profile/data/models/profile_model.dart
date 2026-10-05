import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.userId,
    required super.name,
    required super.birthDate,
    required super.city,
    required super.intent,
    required super.photoRefs,
    required super.familyInvolvementOptIn,
    super.photoVisibility,
    super.educationLevel,
    super.occupation,
    super.religiousPracticeNote,
    super.madhhab,
  });

  factory ProfileModel.fromEntity(Profile p) => ProfileModel(
    userId: p.userId,
    name: p.name,
    birthDate: p.birthDate,
    city: p.city,
    intent: p.intent,
    photoRefs: p.photoRefs,
    familyInvolvementOptIn: p.familyInvolvementOptIn,
    photoVisibility: p.photoVisibility,
    educationLevel: p.educationLevel,
    occupation: p.occupation,
    religiousPracticeNote: p.religiousPracticeNote,
    madhhab: p.madhhab,
  );

  /// The reverse of [toJson]. Throws a [FormatException] when a field
  /// every profile must have is missing or of the wrong type.
  ///
  /// An unknown photo visibility falls back to the most restrictive level
  /// (FR-3.2): a value this version does not know must never open photos.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final city = json['city'];
    final birthDate = json['birthDate'];
    final intent = ProfileIntent.values
        .where((i) => i.name == json['intent'])
        .firstOrNull;
    if (name is! String ||
        city is! String ||
        birthDate is! String ||
        intent == null) {
      throw const FormatException('Profile document is incomplete.');
    }
    return ProfileModel(
      userId: json['userId'] as String,
      name: name,
      // Written in UTC (see [toJson]); shown and compared as a local date.
      birthDate: DateTime.parse(birthDate).toLocal(),
      city: city,
      intent: intent,
      photoRefs: (json['photoRefs'] as List? ?? const []).cast<String>(),
      familyInvolvementOptIn: json['familyInvolvementOptIn'] == true,
      photoVisibility:
          PhotoVisibility.values
              .where((v) => v.name == json['photoVisibility'])
              .firstOrNull ??
          PhotoVisibility.hiddenUntilIUnlock,
      educationLevel: json['educationLevel'] as String?,
      occupation: json['occupation'] as String?,
      religiousPracticeNote: json['religiousPracticeNote'] as String?,
      madhhab: json['madhhab'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    // In UTC, so reading it back gives exactly the same instant on any
    // device: a local time without its offset can be ambiguous (a clock
    // change), and `firestore.rules` refuses a profile update whose birth
    // date differs from the stored one by anything at all (FR-2.5).
    'birthDate': birthDate.toUtc().toIso8601String(),
    'city': city,
    'intent': intent.name,
    'photoRefs': photoRefs,
    'photoVisibility': photoVisibility.name,
    'familyInvolvementOptIn': familyInvolvementOptIn,
    if (educationLevel != null) 'educationLevel': educationLevel,
    if (occupation != null) 'occupation': occupation,
    if (religiousPracticeNote != null)
      'religiousPracticeNote': religiousPracticeNote,
    if (madhhab != null) 'madhhab': madhhab,
  };
}
