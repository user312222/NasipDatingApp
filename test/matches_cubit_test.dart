import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/candidate.dart';
import 'package:binasip/features/matching/domain/entities/candidate_filter.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/entities/swipe_outcome.dart';
import 'package:binasip/features/matching/domain/repositories/matching_repository.dart';
import 'package:binasip/features/matching/domain/usecases/get_my_matches.dart';
import 'package:binasip/features/matching/presentation/bloc/matches_cubit.dart';

class _FakeMatchingRepository implements MatchingRepository {
  _FakeMatchingRepository(this._result);

  final Result<List<Match>> _result;

  @override
  Future<Result<List<Match>>> getMyMatches() async => _result;

  @override
  Future<Result<List<Candidate>>> getCandidates(CandidateFilter filter) =>
      throw UnimplementedError();

  @override
  Future<Result<SwipeOutcome>> swipe({
    required Candidate candidate,
    required SwipeAction action,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> setMatchVisibleToFamily({
    required String matchId,
    required bool visible,
  }) => throw UnimplementedError();
}

Match _match(String id, DateTime matchedAt) => Match(
  id: id,
  matchedAt: matchedAt,
  candidate: Candidate(
    id: 'user_$id',
    name: 'Aday $id',
    age: 27,
    city: 'İstanbul',
    intent: CandidateIntent.marriage,
    avatarColorSeed: 1,
  ),
);

MatchesCubit _cubitWith(Result<List<Match>> result) =>
    MatchesCubit(getMyMatches: GetMyMatches(_FakeMatchingRepository(result)));

void main() {
  test('starts in the loading state', () {
    final cubit = _cubitWith(const Ok(<Match>[]));
    expect(cubit.state, isA<MatchesLoading>());
  });

  test('load emits matches sorted newest first', () async {
    final older = _match('a', DateTime(2026, 1, 1));
    final newest = _match('c', DateTime(2026, 3, 1));
    final middle = _match('b', DateTime(2026, 2, 1));
    final cubit = _cubitWith(Ok([older, newest, middle]));

    await cubit.load();

    final state = cubit.state;
    expect(state, isA<MatchesLoaded>());
    expect((state as MatchesLoaded).matches, [newest, middle, older]);
  });

  test('load emits an empty list when there are no matches', () async {
    final cubit = _cubitWith(const Ok(<Match>[]));

    await cubit.load();

    expect(cubit.state, const MatchesLoaded(<Match>[]));
  });

  test('load surfaces the failure message on error', () async {
    final cubit = _cubitWith(
      const Err(ServerFailure('Eşleşmeler yüklenemedi.')),
    );

    await cubit.load();

    expect(cubit.state, const MatchesError('Eşleşmeler yüklenemedi.'));
  });
}
