import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/messaging/domain/entities/chat_message.dart';
import 'package:binasip/features/messaging/domain/entities/conversation.dart';
import 'package:binasip/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:binasip/features/messaging/domain/usecases/dismiss_family_nudge.dart';
import 'package:binasip/features/messaging/domain/usecases/send_message.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_conversation.dart';
import 'package:binasip/features/messaging/presentation/bloc/chat_cubit.dart';

class _FakeMessagingRepository implements MessagingRepository {
  final streams = <StreamController<Result<Conversation>>>[];
  Completer<Result<void>>? pendingSend;
  final sentTexts = <String>[];
  final dismissedMatchIds = <String>[];

  StreamController<Result<Conversation>> get stream => streams.last;

  @override
  Stream<Result<Conversation>> watchConversation({
    required String matchId,
    required String otherPartyName,
    required int otherPartyAvatarSeed,
  }) {
    final controller = StreamController<Result<Conversation>>();
    streams.add(controller);
    return controller.stream;
  }

  @override
  Future<Result<void>> sendMessage({
    required String matchId,
    required String text,
  }) {
    sentTexts.add(text);
    final completer = Completer<Result<void>>();
    pendingSend = completer;
    return completer.future;
  }

  @override
  Future<Result<void>> dismissFamilyNudge(String matchId) async {
    dismissedMatchIds.add(matchId);
    return const Ok(null);
  }

  @override
  Future<Result<Map<String, ChatMessage>>> getLastMessages(
    List<String> matchIds,
  ) => throw UnimplementedError();
}

ChatMessage _msg(String text) => ChatMessage(
  id: 'id_$text',
  text: text,
  sentAt: DateTime(2026, 1, 1),
  sender: MessageSender.them,
);

Conversation _conversation(
  List<ChatMessage> messages, {
  bool familyNudgeShown = false,
}) => Conversation(
  matchId: 'm1',
  otherPartyName: 'Deniz',
  otherPartyAvatarSeed: 3,
  messages: messages,
  familyNudgeShown: familyNudgeShown,
);

({ChatCubit cubit, _FakeMessagingRepository repo}) _setup() {
  final repo = _FakeMessagingRepository();
  final cubit = ChatCubit(
    watchConversation: WatchConversation(repo),
    sendMessage: SendMessage(repo),
    dismissFamilyNudge: DismissFamilyNudge(repo),
  );
  return (cubit: cubit, repo: repo);
}

void _open(ChatCubit cubit) =>
    cubit.open(matchId: 'm1', otherPartyName: 'Deniz', otherPartyAvatarSeed: 3);

void main() {
  test('starts loading and stays loading until the stream delivers', () async {
    final s = _setup();
    expect(s.cubit.state, isA<ChatLoading>());

    _open(s.cubit);
    await pumpEventQueue();

    expect(s.cubit.state, isA<ChatLoading>());
  });

  test('every stream event updates the loaded conversation live', () async {
    final s = _setup();
    _open(s.cubit);

    s.repo.stream.add(Ok(_conversation([_msg('a')])));
    await pumpEventQueue();
    expect((s.cubit.state as ChatLoaded).conversation.messages, [_msg('a')]);

    s.repo.stream.add(Ok(_conversation([_msg('a'), _msg('b')])));
    await pumpEventQueue();
    expect((s.cubit.state as ChatLoaded).conversation.messages, [
      _msg('a'),
      _msg('b'),
    ]);
  });

  test('a stream failure becomes ChatError', () async {
    final s = _setup();
    _open(s.cubit);

    s.repo.stream.add(const Err(ServerFailure('Sohbet yüklenemedi.')));
    await pumpEventQueue();

    expect(s.cubit.state, const ChatError('Sohbet yüklenemedi.'));
  });

  group('send', () {
    test('is ignored before the conversation has loaded', () async {
      final s = _setup();
      _open(s.cubit);

      await s.cubit.send('merhaba');

      expect(s.repo.sentTexts, isEmpty);
      expect(s.cubit.state, isA<ChatLoading>());
    });

    test('is ignored for blank text', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([])));
      await pumpEventQueue();

      await s.cubit.send('   ');

      expect(s.repo.sentTexts, isEmpty);
    });

    test('sends trimmed text, flags isSending, then clears it', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([])));
      await pumpEventQueue();

      final future = s.cubit.send('  merhaba  ');
      expect((s.cubit.state as ChatLoaded).isSending, isTrue);
      expect(s.repo.sentTexts, ['merhaba']);

      s.repo.pendingSend!.complete(const Ok(null));
      await future;

      final state = s.cubit.state as ChatLoaded;
      expect(state.isSending, isFalse);
      expect(state.sendError, isNull);
    });

    test('keeps a message the stream delivered while sending', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([])));
      await pumpEventQueue();

      final future = s.cubit.send('merhaba');
      // The live stream already echoes the new message before the write's
      // own future resolves.
      s.repo.stream.add(Ok(_conversation([_msg('merhaba')])));
      await pumpEventQueue();
      s.repo.pendingSend!.complete(const Ok(null));
      await future;

      final state = s.cubit.state as ChatLoaded;
      expect(state.conversation.messages, [_msg('merhaba')]);
      expect(state.isSending, isFalse);
    });

    test('a failure sets sendError and keeps the message list', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([_msg('a')])));
      await pumpEventQueue();

      final future = s.cubit.send('merhaba');
      s.repo.pendingSend!.complete(
        const Err(ServerFailure('Mesaj gönderilemedi.')),
      );
      await future;

      final state = s.cubit.state as ChatLoaded;
      expect(state.sendError, 'Mesaj gönderilemedi.');
      expect(state.isSending, isFalse);
      expect(state.conversation.messages, [_msg('a')]);
    });

    test('sendError is cleared by the next stream update', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([])));
      await pumpEventQueue();
      final future = s.cubit.send('merhaba');
      s.repo.pendingSend!.complete(const Err(ServerFailure('Hata')));
      await future;
      expect((s.cubit.state as ChatLoaded).sendError, 'Hata');

      s.repo.stream.add(Ok(_conversation([_msg('x')])));
      await pumpEventQueue();

      expect((s.cubit.state as ChatLoaded).sendError, isNull);
    });
  });

  group('dismissFamilyNudge', () {
    test('flips the flag optimistically and persists it', () async {
      final s = _setup();
      _open(s.cubit);
      s.repo.stream.add(Ok(_conversation([_msg('a')])));
      await pumpEventQueue();

      await s.cubit.dismissFamilyNudge();

      expect(
        (s.cubit.state as ChatLoaded).conversation.familyNudgeShown,
        isTrue,
      );
      expect(s.repo.dismissedMatchIds, ['m1']);
    });

    test('does nothing before the conversation has loaded', () async {
      final s = _setup();
      _open(s.cubit);

      await s.cubit.dismissFamilyNudge();

      expect(s.repo.dismissedMatchIds, isEmpty);
    });
  });

  group('subscription lifecycle', () {
    test('closing the cubit cancels the stream subscription', () async {
      final s = _setup();
      _open(s.cubit);
      expect(s.repo.stream.hasListener, isTrue);

      await s.cubit.close();

      expect(s.repo.stream.hasListener, isFalse);
    });

    test('re-opening cancels the previous subscription', () async {
      final s = _setup();
      _open(s.cubit);
      final first = s.repo.stream;

      _open(s.cubit);
      await pumpEventQueue();

      expect(first.hasListener, isFalse);
      expect(s.repo.stream.hasListener, isTrue);
    });
  });
}
