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

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'city': city,
    'intent': intent.name,
    'photoRefs': photoRefs,
    'photoVisibility': photoVisibility.name,
    'familyInvolvementOptIn': familyInvolvementOptIn,
    if (educationLevel != null) 'educationLevel': educationLevel,
    if (occupation != null) 'occupation': occupation,
    if (religiousPracticeNote != null) 'religiousPracticeNote': religiousPracticeNote,
    if (madhhab != null) 'madhhab': madhhab,
  };
}
