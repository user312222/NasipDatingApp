import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/usecases/get_candidates.dart';
import 'package:binasip/features/matching/domain/usecases/set_match_visible_to_family.dart';
import 'package:binasip/features/matching/domain/usecases/swipe_candidate.dart';
import 'package:binasip/features/matching/presentation/bloc/matching_cubit.dart';

import 'support/fakes.dart';

MatchingCubit _cubitWith(FakeMatchingRepository repo) => MatchingCubit(
  getCandidates: GetCandidates(repo),
  swipeCandidate: SwipeCandidate(repo),
  setMatchVisibleToFamily: SetMatchVisibleToFamily(repo),
);

void main() {
  group('setMatchVisibleToFamily (the switch on the match celebration)', () {
    test('saves the choice for that match and reports success', () async {
      final repo = FakeMatchingRepository(const Ok(<Match>[]));
      final cubit = _cubitWith(repo);

      final saved = await cubit.setMatchVisibleToFamily(
        matchId: 'm1',
        visible: true,
      );

      expect(saved, isTrue);
      expect(repo.familyVisibleCalls, [(matchId: 'm1', visible: true)]);
    });

    test('reports a failed save', () async {
      final repo = FakeMatchingRepository(const Ok(<Match>[]))
        ..familyVisibleResult = const Err(ServerFailure('Kaydedilemedi.'));
      final cubit = _cubitWith(repo);

      final saved = await cubit.setMatchVisibleToFamily(
        matchId: 'm1',
        visible: true,
      );

      expect(saved, isFalse);
    });

    test('does not disturb the discovery state', () async {
      final cubit = _cubitWith(FakeMatchingRepository(const Ok(<Match>[])));
      final states = <MatchingState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.setMatchVisibleToFamily(matchId: 'm1', visible: false);
      await pumpEventQueue();
      await sub.cancel();

      expect(states, isEmpty);
    });
  });
}
