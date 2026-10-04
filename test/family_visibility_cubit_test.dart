import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/usecases/get_match_visible_to_family.dart';
import 'package:binasip/features/matching/domain/usecases/set_match_visible_to_family.dart';
import 'package:binasip/features/matching/presentation/bloc/family_visibility_cubit.dart';

import 'support/fakes.dart';

void main() {
  late FakeMatchingRepository repo;

  FamilyVisibilityCubit cubit() => FamilyVisibilityCubit(
    getMatchVisibleToFamily: GetMatchVisibleToFamily(repo),
    setMatchVisibleToFamily: SetMatchVisibleToFamily(repo),
  );

  setUp(() => repo = FakeMatchingRepository(const Ok(<Match>[])));

  test('starts loading', () {
    expect(cubit().state, const FamilyVisibilityLoading());
  });

  test('load reports the stored choice', () async {
    repo.familyVisible = const Ok(true);
    final c = cubit();

    await c.load('m1');

    expect(c.state, const FamilyVisibilityReady(visible: true));
  });

  test('a failed load leaves the control unavailable', () async {
    repo.familyVisible = const Err(ServerFailure('Okunamadı.'));
    final c = cubit();

    await c.load('m1');

    expect(c.state, const FamilyVisibilityUnavailable());
  });

  test('setVisible flips at once, saves, then settles', () async {
    final c = cubit();
    await c.load('m1');
    final states = <FamilyVisibilityState>[];
    final sub = c.stream.listen(states.add);

    await c.setVisible(true);
    await pumpEventQueue();
    await sub.cancel();

    expect(states, const [
      FamilyVisibilityReady(visible: true, isSaving: true),
      FamilyVisibilityReady(visible: true),
    ]);
    expect(repo.familyVisibleCalls, [(matchId: 'm1', visible: true)]);
  });

  test('a failed save goes back to the stored value and flags it', () async {
    repo.familyVisible = const Ok(true);
    repo.familyVisibleResult = const Err(ServerFailure('Kaydedilemedi.'));
    final c = cubit();
    await c.load('m1');

    await c.setVisible(false);

    expect(
      c.state,
      const FamilyVisibilityReady(visible: true, saveFailed: true),
    );
  });

  test('setVisible does nothing before the choice has loaded', () async {
    final c = cubit();

    await c.setVisible(true);

    expect(c.state, const FamilyVisibilityLoading());
    expect(repo.familyVisibleCalls, isEmpty);
  });

  test('closing while a load is in flight does not emit', () async {
    final c = cubit();
    final loading = c.load('m1');

    await c.close();
    await loading;

    expect(c.isClosed, isTrue);
  });
}
