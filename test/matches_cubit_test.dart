import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/usecases/get_my_matches.dart';
import 'package:binasip/features/matching/presentation/bloc/matches_cubit.dart';
import 'package:binasip/features/messaging/domain/entities/chat_message.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_last_messages.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_read_times.dart';

import 'support/fakes.dart';

MatchesCubit _cubitWith(
  Result<List<Match>> matches, {
  Result<Map<String, ChatMessage>> previews = const Ok({}),
  FakeMessagingRepository? messaging,
}) {
  final repo = messaging ?? FakeMessagingRepository(previews);
  return MatchesCubit(
    getMyMatches: GetMyMatches(FakeMatchingRepository(matches)),
    watchLastMessages: WatchLastMessages(repo),
    watchReadTimes: WatchReadTimes(repo),
  );
}

void main() {
  test('starts in the loading state', () {
    final cubit = _cubitWith(const Ok(<Match>[]));
    expect(cubit.state, isA<MatchesLoading>());
  });

  test('load emits matches sorted newest first', () async {
    final older = testMatch('a', DateTime(2026, 1, 1));
    final newest = testMatch('c', DateTime(2026, 3, 1));
    final middle = testMatch('b', DateTime(2026, 2, 1));
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

  group('previews', () {
    test('are attached and matches re-ordered by latest activity', () async {
      final a = testMatch('a', DateTime(2026, 1, 1));
      final b = testMatch('b', DateTime(2026, 2, 1));
      // `a` is the older match but has the most recent message.
      final lastA = theirMessage('selam', DateTime(2026, 3, 1));
      final cubit = _cubitWith(Ok([a, b]), previews: Ok({'a': lastA}));

      await cubit.load();
      await pumpEventQueue();

      final state = cubit.state as MatchesLoaded;
      expect(state.matches, [a, b]);
      expect(state.previews, {'a': lastA});
    });

    test('are requested for every match id', () async {
      final messaging = FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(
        Ok([
          testMatch('a', DateTime(2026, 1, 1)),
          testMatch('b', DateTime(2026, 2, 1)),
        ]),
        messaging: messaging,
      );

      await cubit.load();

      expect(messaging.lastRequestedIds, unorderedEquals(['a', 'b']));
    });

    test('update live and re-order the list without reloading', () async {
      final a = testMatch('a', DateTime(2026, 1, 1));
      final b = testMatch('b', DateTime(2026, 2, 1));
      final messaging = FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(Ok([a, b]), messaging: messaging);
      await cubit.load();
      await pumpEventQueue();
      expect((cubit.state as MatchesLoaded).matches, [b, a]);

      final lastA = theirMessage('yeni', DateTime(2026, 3, 1));
      messaging.previews.add(Ok({'a': lastA}));
      await pumpEventQueue();

      final state = cubit.state as MatchesLoaded;
      expect(state.matches, [a, b]);
      expect(state.previews, {'a': lastA});
    });

    test('closing the cubit cancels the preview subscription', () async {
      final messaging = FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(
        Ok([testMatch('a', DateTime(2026, 1, 1))]),
        messaging: messaging,
      );
      await cubit.load();
      expect(messaging.previews.hasListener, isTrue);

      await cubit.close();

      expect(messaging.previews.hasListener, isFalse);
    });

    test('a failed preview fetch keeps the list as it was', () async {
      final a = testMatch('a', DateTime(2026, 1, 1));
      final cubit = _cubitWith(
        Ok([a]),
        previews: const Err(ServerFailure('Mesajlar yüklenemedi.')),
      );

      await cubit.load();
      await pumpEventQueue();

      expect(cubit.state, MatchesLoaded([a]));
    });

    test('no preview request is made when there are no matches', () async {
      final messaging = FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(const Ok(<Match>[]), messaging: messaging);

      await cubit.load();

      expect(messaging.lastRequestedIds, isNull);
    });
  });

  group('unread', () {
    final theirs = theirMessage('selam', DateTime(2026, 3, 1, 12));
    final mine = myMessage('selam', DateTime(2026, 3, 1, 12));

    Future<({MatchesCubit cubit, FakeMessagingRepository repo})> loaded(
      ChatMessage last,
    ) async {
      final repo = FakeMessagingRepository(Ok({'a': last}));
      final cubit = _cubitWith(
        Ok([testMatch('a', DateTime(2026, 1, 1))]),
        messaging: repo,
      );
      await cubit.load();
      await pumpEventQueue();
      return (cubit: cubit, repo: repo);
    }

    MatchesLoaded stateOf(MatchesCubit cubit) => cubit.state as MatchesLoaded;

    test('is not shown until the read times have loaded', () async {
      final s = await loaded(theirs);

      expect(stateOf(s.cubit).isUnread('a'), isFalse);
    });

    test('their latest message in a never-opened chat is unread', () async {
      final s = await loaded(theirs);

      s.repo.readTimes.add(const Ok({}));
      await pumpEventQueue();

      expect(stateOf(s.cubit).isUnread('a'), isTrue);
    });

    test(
      'opening the chat clears it, a newer message brings it back',
      () async {
        final s = await loaded(theirs);

        s.repo.readTimes.add(Ok({'a': DateTime(2026, 3, 1, 13)}));
        await pumpEventQueue();
        expect(stateOf(s.cubit).isUnread('a'), isFalse);

        s.repo.previews.add(
          Ok({'a': theirMessage('tekrar', DateTime(2026, 3, 1, 14))}),
        );
        await pumpEventQueue();
        expect(stateOf(s.cubit).isUnread('a'), isTrue);
      },
    );

    test('my own latest message is never unread', () async {
      final s = await loaded(mine);

      s.repo.readTimes.add(const Ok({}));
      await pumpEventQueue();

      expect(stateOf(s.cubit).isUnread('a'), isFalse);
    });

    test('a failed read-times stream leaves nothing flagged', () async {
      final s = await loaded(theirs);

      s.repo.readTimes.add(
        const Err(ServerFailure('Okunma bilgisi yüklenemedi.')),
      );
      await pumpEventQueue();

      expect(stateOf(s.cubit).isUnread('a'), isFalse);
    });

    test('closing the cubit cancels the read-times subscription', () async {
      final s = await loaded(theirs);
      expect(s.repo.readTimes.hasListener, isTrue);

      await s.cubit.close();

      expect(s.repo.readTimes.hasListener, isFalse);
    });
  });
}
