import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/profile/data/models/profile_model.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/usecases/get_profile.dart';
import 'package:binasip/features/profile/domain/usecases/save_profile.dart';
import 'package:binasip/features/profile/presentation/bloc/profile_edit_cubit.dart';

import 'support/fakes.dart';

void main() {
  late FakeProfileRepository repo;
  late ProfileEditCubit cubit;

  // As the real repository hands it out: the data layer's model, which is
  // a `Profile` but never equal to a plain one.
  Profile storedProfile({String? religiousPracticeNote, String? madhhab}) =>
      ProfileModel.fromEntity(
        testProfile(
          religiousPracticeNote: religiousPracticeNote,
          madhhab: madhhab,
        ),
      );

  final stored = storedProfile();

  /// The stored profile's own values, with the given fields replaced.
  ProfileEdits edits(
    Profile from, {
    String? name,
    String? city,
    ProfileIntent? intent,
    PhotoVisibility? photoVisibility,
    bool? familyInvolvementOptIn,
    String? occupation,
    String? religiousPracticeNote,
    String? madhhab,
  }) => ProfileEdits(
    name: name ?? from.name,
    city: city ?? from.city,
    intent: intent ?? from.intent,
    photoVisibility: photoVisibility ?? from.photoVisibility,
    familyInvolvementOptIn:
        familyInvolvementOptIn ?? from.familyInvolvementOptIn,
    educationLevel: from.educationLevel,
    occupation: occupation ?? from.occupation,
    religiousPracticeNote: religiousPracticeNote ?? from.religiousPracticeNote,
    madhhab: madhhab ?? from.madhhab,
  );

  Future<void> loadWith(Profile profile) async {
    repo.stored = Ok(profile);
    await cubit.load('me');
  }

  setUp(() {
    repo = FakeProfileRepository();
    cubit = ProfileEditCubit(
      getProfile: GetProfile(repo),
      saveProfile: SaveProfile(repo),
    );
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('starts from the stored profile', () async {
      await loadWith(stored);

      expect(cubit.state, ProfileEditReady(stored));
    });

    test('says so when there is no profile yet', () async {
      await cubit.load('me');

      expect(
        cubit.state,
        const ProfileEditUnavailable('Henüz bir profilin yok.'),
      );
    });

    test('reports a failed read', () async {
      repo.stored = const Err(ServerFailure('Profilin yüklenemedi.'));

      await cubit.load('me');

      expect(
        cubit.state,
        const ProfileEditUnavailable('Profilin yüklenemedi.'),
      );
    });

    test('closing while loading does not emit', () async {
      final loading = cubit.load('me');

      await cubit.close();
      await loading;

      expect(cubit.isClosed, isTrue);
    });
  });

  group('save', () {
    test('writes the edited fields', () async {
      await loadWith(stored);

      await cubit.save(
        edits(
          stored,
          name: 'Zeynep Ada',
          city: 'Ankara',
          intent: ProfileIntent.notSureYet,
          photoVisibility: PhotoVisibility.autoOnMatch,
          familyInvolvementOptIn: true,
          occupation: 'Şehir plancısı',
        ),
      );

      final saved = repo.saved.single;
      expect(saved.name, 'Zeynep Ada');
      expect(saved.city, 'Ankara');
      expect(saved.intent, ProfileIntent.notSureYet);
      expect(saved.photoVisibility, PhotoVisibility.autoOnMatch);
      expect(saved.familyInvolvementOptIn, isTrue);
      expect(saved.occupation, 'Şehir plancısı');
      expect(cubit.state, ProfileEditSaved(saved, changed: true));
    });

    test('carries over what the screen cannot change', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, city: 'Ankara'));

      final saved = repo.saved.single;
      expect(saved.userId, stored.userId);
      expect(saved.birthDate, stored.birthDate);
      expect(saved.photoRefs, stored.photoRefs);
      expect(saved.educationLevel, stored.educationLevel);
    });

    test('trims text and drops an optional field left blank', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, name: '  Zeynep Ada ', occupation: '   '));

      final saved = repo.saved.single;
      expect(saved.name, 'Zeynep Ada');
      expect(saved.occupation, isNull);
    });

    test('with nothing changed writes nothing', () async {
      await loadWith(stored);

      await cubit.save(ProfileEdits.of(stored));

      expect(repo.saved, isEmpty);
      expect(cubit.state, ProfileEditSaved(stored, changed: false));
    });

    test('spaces around a value are not a change', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, name: ' ${stored.name}  '));

      expect(repo.saved, isEmpty);
    });

    // Documents written before blanks were dropped can hold ''.
    test('an empty string stored where nothing is typed is not a change', () {
      final old = Profile(
        userId: 'me',
        name: 'Zeynep',
        birthDate: DateTime(1999),
        city: 'İstanbul',
        intent: ProfileIntent.marriage,
        photoRefs: const ['photo_0.jpg'],
        familyInvolvementOptIn: false,
        occupation: '',
      );

      expect(ProfileEdits.of(old).changes(old), isFalse);
    });

    test('needs a name and a city', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, name: '   '));
      expect(
        (cubit.state as ProfileEditReady).error,
        'Ad ve şehir boş bırakılamaz.',
      );

      await cubit.save(edits(stored, city: ''));
      expect(
        (cubit.state as ProfileEditReady).error,
        'Ad ve şehir boş bırakılamaz.',
      );
      expect(repo.saved, isEmpty);
    });

    // firestore.rules rejects a longer name; say so before the write does.
    test('keeps the name within 60 characters', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, name: 'a' * 61));

      expect(
        (cubit.state as ProfileEditReady).error,
        'Ad en fazla 60 karakter olabilir.',
      );
      expect(repo.saved, isEmpty);
    });

    test('shows the saving state while the write is under way', () async {
      await loadWith(stored);
      repo.pendingSave = Completer<void>();

      final saving = cubit.save(edits(stored, city: 'Ankara'));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, ProfileEditReady(stored, saving: true));
      // A second press while saving does not write twice.
      await cubit.save(edits(stored, city: 'Bursa'));
      expect(repo.saved, hasLength(1));

      repo.pendingSave!.complete();
      await saving;
      expect(cubit.state, isA<ProfileEditSaved>());
    });

    test('a failed write keeps the stored profile and says why', () async {
      await loadWith(stored);
      repo.saveResult = const Err(ServerFailure('Profil kaydedilemedi.'));

      await cubit.save(edits(stored, city: 'Ankara'));

      expect(
        cubit.state,
        ProfileEditReady(stored, error: 'Profil kaydedilemedi.'),
      );
    });

    test('leaving while saving does not emit', () async {
      await loadWith(stored);
      repo.pendingSave = Completer<void>();
      final saving = cubit.save(edits(stored, city: 'Ankara'));
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      repo.pendingSave!.complete();
      await saving;

      expect(cubit.isClosed, isTrue);
    });
  });

  // KVKK m.6: religious data needs its own consent - when it is new.
  group('religious data consent', () {
    const consentError =
        'Dini pratik/mezhep bilgini paylaşmak için onayı işaretlemelisin '
        '— ya da bu alanları boş bırakabilirsin.';

    test('a new religious note is not saved without it', () async {
      await loadWith(stored);

      await cubit.save(
        edits(stored, religiousPracticeNote: 'Namazlarımı kılarım.'),
      );

      expect((cubit.state as ProfileEditReady).error, consentError);
      expect(repo.saved, isEmpty);
    });

    test('a new madhhab is not saved without it', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, madhhab: 'Sünni'));

      expect((cubit.state as ProfileEditReady).error, consentError);
      expect(repo.saved, isEmpty);
    });

    test('with the box ticked both are saved', () async {
      await loadWith(stored);

      await cubit.save(
        edits(
          stored,
          religiousPracticeNote: 'Namazlarımı kılarım.',
          madhhab: 'Sünni',
        ),
        sensitiveDataConsent: true,
      );

      expect(repo.saved.single.religiousPracticeNote, 'Namazlarımı kılarım.');
      expect(repo.saved.single.madhhab, 'Sünni');
    });

    test('rewording what is stored asks again', () async {
      final withNote = storedProfile(religiousPracticeNote: 'Oruç tutarım.');
      await loadWith(withNote);

      await cubit.save(
        edits(withNote, religiousPracticeNote: 'Oruç tutar, namaz kılarım.'),
      );

      expect((cubit.state as ProfileEditReady).error, consentError);
    });

    test('what is already stored needs no new consent', () async {
      final withBoth = storedProfile(
        religiousPracticeNote: 'Oruç tutarım.',
        madhhab: 'Sünni',
      );
      await loadWith(withBoth);

      await cubit.save(edits(withBoth, city: 'Ankara'));

      expect(repo.saved.single.city, 'Ankara');
      expect(repo.saved.single.madhhab, 'Sünni');
    });

    test('"Belirtmek istemiyorum" discloses nothing', () async {
      await loadWith(stored);

      await cubit.save(edits(stored, madhhab: madhhabNoAnswer));

      expect(repo.saved.single.madhhab, madhhabNoAnswer);
    });

    test('removing religious data needs no consent', () async {
      final withBoth = storedProfile(
        religiousPracticeNote: 'Oruç tutarım.',
        madhhab: 'Sünni',
      );
      await loadWith(withBoth);

      await cubit.save(
        ProfileEdits(
          name: withBoth.name,
          city: withBoth.city,
          intent: withBoth.intent,
          photoVisibility: withBoth.photoVisibility,
          familyInvolvementOptIn: withBoth.familyInvolvementOptIn,
          educationLevel: withBoth.educationLevel,
          occupation: withBoth.occupation,
          religiousPracticeNote: '',
          madhhab: '',
        ),
      );

      expect(repo.saved.single.religiousPracticeNote, isNull);
      expect(repo.saved.single.madhhab, isNull);
    });
  });
}
