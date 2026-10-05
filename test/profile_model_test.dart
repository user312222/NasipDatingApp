import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/features/profile/data/models/profile_model.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';

import 'support/fakes.dart';

void main() {
  test('a profile survives being written and read back', () {
    final profile = ProfileModel.fromEntity(
      testProfile(
        religiousPracticeNote: 'Oruç tutarım.',
        madhhab: 'Sünni',
        photoVisibility: PhotoVisibility.onRequestOnly,
      ),
    );

    expect(ProfileModel.fromJson(profile.toJson()), profile);
  });

  // firestore.rules refuses an update whose birth date differs from the
  // stored one at all (FR-2.5), so the round trip has to be exact.
  test('the birth date comes back as the same instant, as a local date', () {
    final birthDate = DateTime(1999, 3, 28, 2, 30);
    final json = ProfileModel(
      userId: 'me',
      name: 'Zeynep',
      birthDate: birthDate,
      city: 'İstanbul',
      intent: ProfileIntent.marriage,
      photoRefs: const ['photo_0.jpg'],
      familyInvolvementOptIn: false,
    ).toJson();

    expect(json['birthDate'], endsWith('Z'));
    final read = ProfileModel.fromJson(json).birthDate;
    expect(read.isUtc, isFalse);
    expect(read.isAtSameMomentAs(birthDate), isTrue);
    expect(read.day, birthDate.day);
  });

  test('optional fields that were never written stay empty', () {
    final json = ProfileModel.fromEntity(testProfile()).toJson()
      ..remove('educationLevel')
      ..remove('occupation');

    final profile = ProfileModel.fromJson(json);

    expect(profile.educationLevel, isNull);
    expect(profile.occupation, isNull);
    expect(profile.religiousPracticeNote, isNull);
    expect(profile.madhhab, isNull);
  });

  // FR-3.2: a value this version does not know must never open photos.
  test('an unknown photo visibility reads as the most restrictive', () {
    final json = ProfileModel.fromEntity(
      testProfile(photoVisibility: PhotoVisibility.autoOnMatch),
    ).toJson()..['photoVisibility'] = 'everyone';

    expect(
      ProfileModel.fromJson(json).photoVisibility,
      PhotoVisibility.hiddenUntilIUnlock,
    );
  });

  test('a document missing a required field is refused, not guessed', () {
    for (final field in ['name', 'city', 'birthDate', 'intent']) {
      final json = ProfileModel.fromEntity(testProfile()).toJson()
        ..remove(field);

      expect(
        () => ProfileModel.fromJson(json),
        throwsFormatException,
        reason: field,
      );
    }
  });
}
