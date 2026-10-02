import 'dart:async';

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
import 'package:binasip/features/messaging/domain/entities/chat_message.dart';
import 'package:binasip/features/messaging/domain/entities/conversation.dart';
import 'package:binasip/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_last_messages.dart';

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

class _FakeMessagingRepository implements MessagingRepository {
  /// Optionally seeds the first emission, like a Firestore listener that
  /// reports right after subscribing.
  _FakeMessagingRepository([Result<Map<String, ChatMessage>>? first]) {
    if (first != null) controller.add(first);
  }

  final controller = StreamController<Result<Map<String, ChatMessage>>>();
  List<String>? lastRequestedIds;

  @override
  Stream<Result<Map<String, ChatMessage>>> watchLastMessages(
    List<String> matchIds,
  ) {
    lastRequestedIds = matchIds;
    return controller.stream;
  }

  @override
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> sendMessage({
    required String matchId,
    required String text,
  }) => throw UnimplementedError();

  @override
  Future<Result<void>> dismissFamilyNudge(String matchId) =>
      throw UnimplementedError();
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

ChatMessage _message(String text, DateTime sentAt) => ChatMessage(
  id: 'msg_$text',
  text: text,
  sentAt: sentAt,
  sender: MessageSender.them,
);

MatchesCubit _cubitWith(
  Result<List<Match>> matches, {
  Result<Map<String, ChatMessage>> previews = const Ok({}),
  _FakeMessagingRepository? messaging,
}) => MatchesCubit(
  getMyMatches: GetMyMatches(_FakeMatchingRepository(matches)),
  watchLastMessages: WatchLastMessages(
    messaging ?? _FakeMessagingRepository(previews),
  ),
);

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

  group('previews', () {
    test('are attached and matches re-ordered by latest activity', () async {
      final a = _match('a', DateTime(2026, 1, 1));
      final b = _match('b', DateTime(2026, 2, 1));
      // `a` is the older match but has the most recent message.
      final lastA = _message('selam', DateTime(2026, 3, 1));
      final cubit = _cubitWith(Ok([a, b]), previews: Ok({'a': lastA}));

      await cubit.load();
      await pumpEventQueue();

      final state = cubit.state as MatchesLoaded;
      expect(state.matches, [a, b]);
      expect(state.previews, {'a': lastA});
    });

    test('are requested for every match id', () async {
      final messaging = _FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(
        Ok([
          _match('a', DateTime(2026, 1, 1)),
          _match('b', DateTime(2026, 2, 1)),
        ]),
        messaging: messaging,
      );

      await cubit.load();

      expect(messaging.lastRequestedIds, unorderedEquals(['a', 'b']));
    });

    test('update live and re-order the list without reloading', () async {
      final a = _match('a', DateTime(2026, 1, 1));
      final b = _match('b', DateTime(2026, 2, 1));
      final messaging = _FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(Ok([a, b]), messaging: messaging);
      await cubit.load();
      await pumpEventQueue();
      expect((cubit.state as MatchesLoaded).matches, [b, a]);

      final lastA = _message('yeni', DateTime(2026, 3, 1));
      messaging.controller.add(Ok({'a': lastA}));
      await pumpEventQueue();

      final state = cubit.state as MatchesLoaded;
      expect(state.matches, [a, b]);
      expect(state.previews, {'a': lastA});
    });

    test('closing the cubit cancels the preview subscription', () async {
      final messaging = _FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(
        Ok([_match('a', DateTime(2026, 1, 1))]),
        messaging: messaging,
      );
      await cubit.load();
      expect(messaging.controller.hasListener, isTrue);

      await cubit.close();

      expect(messaging.controller.hasListener, isFalse);
    });

    test('a failed preview fetch keeps the list as it was', () async {
      final a = _match('a', DateTime(2026, 1, 1));
      final cubit = _cubitWith(
        Ok([a]),
        previews: const Err(ServerFailure('Mesajlar yüklenemedi.')),
      );

      await cubit.load();
      await pumpEventQueue();

      expect(cubit.state, MatchesLoaded([a]));
    });

    test('no preview request is made when there are no matches', () async {
      final messaging = _FakeMessagingRepository(const Ok({}));
      final cubit = _cubitWith(const Ok(<Match>[]), messaging: messaging);

      await cubit.load();

      expect(messaging.lastRequestedIds, isNull);
    });
  });
}
