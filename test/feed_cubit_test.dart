import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/feed/domain/entities/daily_question.dart';
import 'package:binasip/features/feed/domain/entities/feed.dart';
import 'package:binasip/features/feed/domain/usecases/delete_my_answer.dart';
import 'package:binasip/features/feed/domain/usecases/set_post_liked.dart';
import 'package:binasip/features/feed/domain/usecases/submit_answer.dart';
import 'package:binasip/features/feed/domain/usecases/watch_feed.dart';
import 'package:binasip/features/feed/presentation/bloc/feed_cubit.dart';

import 'support/fakes.dart';

({FeedCubit cubit, FakeFeedRepository repo}) _setup() {
  final repo = FakeFeedRepository();
  final cubit = FeedCubit(
    watchFeed: WatchFeed(repo),
    submitAnswer: SubmitAnswer(repo),
    deleteMyAnswer: DeleteMyAnswer(repo),
    setPostLiked: SetPostLiked(repo),
  );
  return (cubit: cubit, repo: repo);
}

Future<({FeedCubit cubit, FakeFeedRepository repo})> _loaded([
  List<String> authors = const ['a', 'b'],
]) async {
  final s = _setup();
  s.cubit.start();
  s.repo.feeds.add(Ok(testFeed([for (final a in authors) testPost(a)])));
  await pumpEventQueue();
  return s;
}

void main() {
  group('DailyQuestion', () {
    test('the day key is the unpadded UTC date', () {
      expect(
        DailyQuestion.dayKeyFor(DateTime.utc(2026, 3, 6, 23, 59)),
        '2026-3-6',
      );
      // 01:30 in Istanbul (UTC+3) is still the previous UTC day.
      expect(
        DailyQuestion.dayKeyFor(DateTime.parse('2026-03-07T01:30:00+03:00')),
        '2026-3-6',
      );
    });

    test('everyone gets the same question all day, a new one tomorrow', () {
      final morning = DailyQuestion.forDay(DateTime.utc(2026, 3, 6, 1));
      final night = DailyQuestion.forDay(DateTime.utc(2026, 3, 6, 23));
      final tomorrow = DailyQuestion.forDay(DateTime.utc(2026, 3, 7, 1));

      expect(morning, night);
      expect(tomorrow.text, isNot(morning.text));
      expect(morning.text, isNotEmpty);
    });

    test('the question changes at the next UTC midnight', () {
      final change = DailyQuestion.nextChangeAfter(
        DateTime.utc(2026, 3, 6, 23, 59, 30),
      );

      expect(change, DateTime.utc(2026, 3, 7));
      expect(
        DailyQuestion.forDay(change),
        isNot(
          DailyQuestion.forDay(change.subtract(const Duration(seconds: 1))),
        ),
      );
      // Month and year ends roll over too.
      expect(
        DailyQuestion.nextChangeAfter(DateTime.utc(2026, 12, 31, 12)),
        DateTime.utc(2027),
      );
      // 01:30 in Istanbul is still the previous UTC day: the change is at
      // 03:00 local, not at local midnight.
      expect(
        DailyQuestion.nextChangeAfter(
          DateTime.parse('2026-03-07T01:30:00+03:00'),
        ),
        DateTime.utc(2026, 3, 7),
      );
    });
  });

  group('FeedCubit', () {
    test('starts loading, then shows the feed live', () async {
      final s = _setup();
      expect(s.cubit.state, isA<FeedLoading>());

      s.cubit.start();
      s.repo.feeds.add(Ok(testFeed([testPost('a')])));
      await pumpEventQueue();
      expect((s.cubit.state as FeedLoaded).feed.posts, [testPost('a')]);

      s.repo.feeds.add(Ok(testFeed([testPost('a'), testPost('b')])));
      await pumpEventQueue();
      expect((s.cubit.state as FeedLoaded).feed.posts, hasLength(2));
    });

    test(
      'moves on to the question of the next day when the stream does',
      () async {
        final s = _setup();
        s.cubit.start();
        s.repo.feeds.add(Ok(testFeed([testPost('me', isMine: true)])));
        await pumpEventQueue();
        expect((s.cubit.state as FeedLoaded).feed.mine, isNotNull);

        const tomorrow = DailyQuestion(dayKey: '2026-3-7', text: 'Yeni soru?');
        s.repo.feeds.add(const Ok(Feed(question: tomorrow, posts: [])));
        await pumpEventQueue();

        final feed = (s.cubit.state as FeedLoaded).feed;
        expect(feed.question, tomorrow);
        expect(feed.mine, isNull);
      },
    );

    test('a stream failure becomes FeedError', () async {
      final s = _setup();
      s.cubit.start();

      s.repo.feeds.add(const Err(ServerFailure('Akış yüklenemedi.')));
      await pumpEventQueue();

      expect(s.cubit.state, const FeedError('Akış yüklenemedi.'));
    });

    test('mine and others are split by ownership', () async {
      final s = _setup();
      s.cubit.start();
      s.repo.feeds.add(
        Ok(testFeed([testPost('a'), testPost('me', isMine: true)])),
      );
      await pumpEventQueue();

      final feed = (s.cubit.state as FeedLoaded).feed;
      expect(feed.mine, testPost('me', isMine: true));
      expect(feed.others, [testPost('a')]);
    });

    group('submit', () {
      test('sends the trimmed answer and reports success', () async {
        final s = await _loaded();

        final future = s.cubit.submit('  Kahvaltı ve yürüyüş.  ');
        expect((s.cubit.state as FeedLoaded).isSubmitting, isTrue);
        expect(s.repo.submitted, ['Kahvaltı ve yürüyüş.']);

        s.repo.pendingSubmit!.complete(const Ok(null));
        expect(await future, isTrue);
        expect((s.cubit.state as FeedLoaded).isSubmitting, isFalse);
      });

      test('ignores a blank answer', () async {
        final s = await _loaded();

        expect(await s.cubit.submit('   '), isFalse);
        expect(s.repo.submitted, isEmpty);
      });

      test('refuses an answer over the limit without calling out', () async {
        final s = await _loaded();

        final accepted = await s.cubit.submit(
          'x' * (DailyQuestion.maxAnswerLength + 1),
        );

        expect(accepted, isFalse);
        expect(s.repo.submitted, isEmpty);
        expect((s.cubit.state as FeedLoaded).actionError, contains('280'));
      });

      test('a second submit while one is in flight is ignored', () async {
        final s = await _loaded();

        final first = s.cubit.submit('bir');
        expect(await s.cubit.submit('iki'), isFalse);
        expect(s.repo.submitted, ['bir']);

        s.repo.pendingSubmit!.complete(const Ok(null));
        await first;
      });

      test('a failure keeps the feed and sets a one-shot error', () async {
        final s = await _loaded();

        final future = s.cubit.submit('merhaba');
        s.repo.pendingSubmit!.complete(
          const Err(ServerFailure('Cevabın paylaşılamadı.')),
        );

        expect(await future, isFalse);
        final state = s.cubit.state as FeedLoaded;
        expect(state.actionError, 'Cevabın paylaşılamadı.');
        expect(state.feed.posts, hasLength(2));

        s.repo.feeds.add(Ok(testFeed([testPost('a')])));
        await pumpEventQueue();
        expect((s.cubit.state as FeedLoaded).actionError, isNull);
      });

      test('keeps the spinner if the stream updates mid-submit', () async {
        final s = await _loaded();

        final future = s.cubit.submit('merhaba');
        s.repo.feeds.add(Ok(testFeed([testPost('a')])));
        await pumpEventQueue();
        expect((s.cubit.state as FeedLoaded).isSubmitting, isTrue);

        s.repo.pendingSubmit!.complete(const Ok(null));
        await future;
        expect((s.cubit.state as FeedLoaded).isSubmitting, isFalse);
      });

      test('finishing after the screen was left is dropped', () async {
        final s = await _loaded();

        final future = s.cubit.submit('merhaba');
        await s.cubit.close();
        s.repo.pendingSubmit!.complete(const Ok(null));

        expect(await future, isFalse);
      });
    });

    group('likes', () {
      test('toggles to the opposite of the current state', () async {
        final s = await _loaded();

        await s.cubit.toggleLike(testPost('a'));
        await s.cubit.toggleLike(testPost('b', likedByMe: true));

        expect(s.repo.likeCalls, [
          (postId: 'a_2026-3-6', liked: true),
          (postId: 'b_2026-3-6', liked: false),
        ]);
      });

      test('never likes your own answer', () async {
        final s = await _loaded();

        await s.cubit.toggleLike(testPost('me', isMine: true));

        expect(s.repo.likeCalls, isEmpty);
      });

      test('a failed like surfaces as a one-shot error', () async {
        final s = await _loaded();
        s.repo.likeResult = const Err(ServerFailure('Beğeni kaydedilemedi.'));

        await s.cubit.toggleLike(testPost('a'));

        expect(
          (s.cubit.state as FeedLoaded).actionError,
          'Beğeni kaydedilemedi.',
        );
      });
    });

    test('deleteMine calls the repository and reports a failure', () async {
      final s = await _loaded();
      s.repo.deleteResult = const Err(ServerFailure('Cevabın silinemedi.'));

      await s.cubit.deleteMine();

      expect(s.repo.deleteCalls, 1);
      expect((s.cubit.state as FeedLoaded).actionError, 'Cevabın silinemedi.');
    });

    test('a blocked author disappears at once and stays hidden', () async {
      final s = await _loaded();

      s.cubit.hideAuthor('a');
      expect((s.cubit.state as FeedLoaded).feed.posts, [testPost('b')]);

      s.repo.feeds.add(Ok(testFeed([testPost('a'), testPost('b')])));
      await pumpEventQueue();
      expect((s.cubit.state as FeedLoaded).feed.posts, [testPost('b')]);
    });

    test(
      'closing cancels the subscription; a racing event is dropped',
      () async {
        final s = await _loaded();
        expect(s.repo.feeds.hasListener, isTrue);

        s.repo.feeds.add(Ok(testFeed([testPost('z')])));
        await s.cubit.close();
        await pumpEventQueue();

        expect(s.repo.feeds.hasListener, isFalse);
      },
    );
  });
}
