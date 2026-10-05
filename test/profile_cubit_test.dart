import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/repositories/profile_repository.dart';
import 'package:binasip/features/profile/domain/usecases/save_profile.dart';
import 'package:binasip/features/profile/presentation/bloc/profile_cubit.dart';

class _FakeProfileRepository implements ProfileRepository {
  Result<void> saveResult = const Ok(null);
  final saved = <Profile>[];

  @override
  Future<Result<void>> saveProfile(Profile profile) async {
    saved.add(profile);
    return saveResult;
  }

  @override
  Future<Result<bool>> hasProfile(String userId) async =>
      Ok(saved.any((p) => p.userId == userId));

  @override
  Future<Result<Profile?>> getProfile(String userId) =>
      throw UnimplementedError();
}

void main() {
  late _FakeProfileRepository repo;
  late ProfileCubit cubit;

  final photo = Uint8List.fromList([1, 2, 3]);
  final adultBirthDate = DateTime(DateTime.now().year - 25);

  void fillDetails() => cubit.updateDetails(
    name: 'Zeynep',
    birthDate: adultBirthDate,
    city: 'İstanbul',
  );

  setUp(() {
    repo = _FakeProfileRepository();
    cubit = ProfileCubit(saveProfile: SaveProfile(repo));
  });

  test('a complete draft is saved', () async {
    cubit
      ..updatePhotos([photo])
      ..updateIntent(ProfileIntent.marriage);
    fillDetails();

    await cubit.submit('user_1');

    expect(cubit.state, isA<ProfileSubmitted>());
    expect(repo.saved.single.userId, 'user_1');
    expect(repo.saved.single.photoRefs, hasLength(1));
    // FR-3.2: the most restrictive photo setting unless the user chose.
    expect(
      repo.saved.single.photoVisibility,
      PhotoVisibility.hiddenUntilIUnlock,
    );
  });

  // On the web a later step can be opened by address without the earlier
  // ones; whatever was skipped must stop the save.
  group('a step skipped by address stops the save', () {
    test('no photo (FR-2.1)', () async {
      cubit.updateIntent(ProfileIntent.marriage);
      fillDetails();

      await cubit.submit('user_1');

      expect(
        (cubit.state as ProfileSubmitError).message,
        'En az 1 fotoğraf eklemelisin.',
      );
      expect(repo.saved, isEmpty);
    });

    test('no intent', () async {
      cubit.updatePhotos([photo]);
      fillDetails();

      await cubit.submit('user_1');

      expect(cubit.state, isA<ProfileSubmitError>());
      expect(repo.saved, isEmpty);
    });

    test('no details', () async {
      cubit
        ..updatePhotos([photo])
        ..updateIntent(ProfileIntent.marriage);

      await cubit.submit('user_1');

      expect(cubit.state, isA<ProfileSubmitError>());
      expect(repo.saved, isEmpty);
    });

    test('under 18', () async {
      cubit
        ..updatePhotos([photo])
        ..updateIntent(ProfileIntent.marriage)
        ..updateDetails(
          name: 'Zeynep',
          birthDate: DateTime(DateTime.now().year - 10),
          city: 'İstanbul',
        );

      await cubit.submit('user_1');

      expect(cubit.state, isA<ProfileSubmitError>());
      expect(repo.saved, isEmpty);
    });
  });

  test('a failed save keeps the draft and reports why', () async {
    repo.saveResult = const Err(ServerFailure('Profil kaydedilemedi.'));
    cubit
      ..updatePhotos([photo])
      ..updateIntent(ProfileIntent.marriage);
    fillDetails();

    await cubit.submit('user_1');

    final state = cubit.state as ProfileSubmitError;
    expect(state.message, 'Profil kaydedilemedi.');
    expect(state.draft.name, 'Zeynep');
  });
}
