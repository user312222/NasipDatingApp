import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/usecases/get_match_visible_to_family.dart';
import 'package:binasip/features/matching/domain/usecases/set_match_visible_to_family.dart';
import 'package:binasip/features/matching/presentation/bloc/family_visibility_cubit.dart';
import 'package:binasip/features/messaging/domain/entities/chat_message.dart';
import 'package:binasip/features/messaging/domain/usecases/dismiss_family_nudge.dart';
import 'package:binasip/features/messaging/domain/usecases/mark_conversation_read.dart';
import 'package:binasip/features/messaging/domain/usecases/send_message.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_conversation.dart';
import 'package:binasip/features/messaging/presentation/bloc/chat_cubit.dart';
import 'package:binasip/features/messaging/presentation/screens/chat_screen.dart';
import 'package:binasip/features/safety/domain/usecases/block_user.dart';
import 'package:binasip/features/safety/domain/usecases/report_user.dart';
import 'package:binasip/features/safety/presentation/bloc/safety_cubit.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

void main() {
  late FakeMessagingRepository repo;
  late FakeMatchingRepository matching;

  Future<void> pumpChat(WidgetTester tester) async {
    sl.registerFactory(
      () => FamilyVisibilityCubit(
        getMatchVisibleToFamily: GetMatchVisibleToFamily(matching),
        setMatchVisibleToFamily: SetMatchVisibleToFamily(matching),
      ),
    );
    sl.registerFactory(
      () => ChatCubit(
        watchConversation: WatchConversation(repo),
        sendMessage: SendMessage(repo),
        dismissFamilyNudge: DismissFamilyNudge(repo),
        markConversationRead: MarkConversationRead(repo),
      ),
    );
    final safety = FakeSafetyRepository();
    sl.registerFactory(
      () => SafetyCubit(
        reportUser: ReportUser(safety),
        blockUser: BlockUser(safety),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ChatScreen(
            matchId: 'm1',
            otherPartyUserId: 'user_a',
            otherPartyName: 'Deniz',
            otherPartyAvatarSeed: 3,
          ),
        ),
        GoRoute(
          path: '/family/settings',
          builder: (_, _) => const Scaffold(body: Text('aile ayarları')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  Future<void> loadWith(
    WidgetTester tester,
    List<ChatMessage> messages, {
    bool familyNudgeShown = false,
  }) async {
    repo.conversations.add(
      Ok(testConversation(messages, familyNudgeShown: familyNudgeShown)),
    );
    await pumpChat(tester);
    await tester.pumpAndSettle();
  }

  // Relative to now on purpose: the nudge also fires 7 days after the
  // first message, so fixed dates would drift into that branch.
  final now = DateTime.now();
  final noon = DateTime(now.year, now.month, now.day, 12);

  setUp(() async {
    await sl.reset();
    repo = FakeMessagingRepository();
    matching = FakeMatchingRepository(const Ok(<Match>[]));
  });

  tearDown(() async {
    await sl.reset();
  });

  group('messages', () {
    testWidgets('shows a spinner until the conversation arrives', (
      tester,
    ) async {
      await pumpChat(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders the thread with its times', (tester) async {
      await loadWith(tester, [
        theirMessage('selam', DateTime(now.year, now.month, now.day, 9, 5)),
        myMessage('merhaba', DateTime(now.year, now.month, now.day, 9, 7)),
      ]);

      expect(find.text('selam'), findsOneWidget);
      expect(find.text('merhaba'), findsOneWidget);
      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('09:07'), findsOneWidget);
    });

    testWidgets('an empty thread invites the first message', (tester) async {
      await loadWith(tester, []);

      expect(find.text('Deniz ile eşleştin.'), findsOneWidget);
      expect(
        find.text('İlk mesajı sen yaz — nazik bir merhaba yeter.'),
        findsOneWidget,
      );
    });

    testWidgets('a message from the other party appears live', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);
      expect(find.text('nasılsın?'), findsNothing);

      repo.conversations.add(
        Ok(
          testConversation([
            theirMessage('selam', noon),
            theirMessage('nasılsın?', noon.add(const Duration(minutes: 1))),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('nasılsın?'), findsOneWidget);
    });

    testWidgets('marks an incoming message as read', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      expect(repo.markedReadMatchIds, ['m1']);
    });

    testWidgets('shows the load failure instead of the thread', (tester) async {
      repo.conversations.add(const Err(ServerFailure('Sohbet yüklenemedi.')));
      await pumpChat(tester);
      await tester.pumpAndSettle();

      expect(find.text('Sohbet yüklenemedi.'), findsOneWidget);
    });
  });

  group('sending', () {
    testWidgets('the send button sends the trimmed text and clears the field', (
      tester,
    ) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      await tester.enterText(find.byType(TextField), '  merhaba  ');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(repo.sentTexts, ['merhaba']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('Enter sends too', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'enter ile');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(repo.sentTexts, ['enter ile']);
    });

    testWidgets('a blank message is not sent', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(repo.sentTexts, isEmpty);
    });

    testWidgets('a second send is blocked while one is in flight', (
      tester,
    ) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      await tester.enterText(find.byType(TextField), 'bir');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'iki');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      expect(repo.sentTexts, ['bir']);

      repo.pendingSend!.complete(const Ok(null));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      expect(repo.sentTexts, ['bir', 'iki']);
    });

    testWidgets('a failed send shows a SnackBar and keeps the thread', (
      tester,
    ) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      await tester.enterText(find.byType(TextField), 'merhaba');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      repo.pendingSend!.complete(
        const Err(ServerFailure('Mesaj gönderilemedi.')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mesaj gönderilemedi.'), findsOneWidget);
      expect(find.text('selam'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('family nudge', () {
    List<ChatMessage> thirty() => [
      for (var i = 0; i < 30; i++)
        theirMessage('m$i', noon.add(Duration(minutes: i))),
    ];

    testWidgets('is hidden in a short, new conversation', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);

      expect(
        find.text('Bir sonraki adımı düşünmek ister misin?'),
        findsNothing,
      );
    });

    testWidgets('appears after 30 messages', (tester) async {
      await loadWith(tester, thirty());

      expect(
        find.text('Bir sonraki adımı düşünmek ister misin?'),
        findsOneWidget,
      );
    });

    testWidgets('appears 7 days after the first message', (tester) async {
      await loadWith(tester, [
        theirMessage('eski', now.subtract(const Duration(days: 8))),
        theirMessage('yeni', noon),
      ]);

      expect(
        find.text('Bir sonraki adımı düşünmek ister misin?'),
        findsOneWidget,
      );
    });

    testWidgets('stays hidden once it was already shown', (tester) async {
      await loadWith(tester, thirty(), familyNudgeShown: true);

      expect(
        find.text('Bir sonraki adımı düşünmek ister misin?'),
        findsNothing,
      );
    });

    testWidgets('its button opens the family settings', (tester) async {
      await loadWith(tester, thirty());

      await tester.tap(find.text('Aileni sürece dahil et'));
      await tester.pumpAndSettle();

      expect(find.text('aile ayarları'), findsOneWidget);
    });

    testWidgets('dismissing hides it and records that it was shown', (
      tester,
    ) async {
      await loadWith(tester, thirty());

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        find.text('Bir sonraki adımı düşünmek ister misin?'),
        findsNothing,
      );
      expect(repo.dismissedMatchIds, ['m1']);
    });
  });

  group('"aileme göster" (FR-8.4)', () {
    Finder familyButton({required bool on}) =>
        find.byTooltip(on ? 'Ailene gösteriliyor' : 'Aileme göster');

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(familyButton(on: false));
      await tester.pumpAndSettle();
    }

    testWidgets('the app bar button reflects the stored choice', (
      tester,
    ) async {
      matching.familyVisible = const Ok(true);
      await loadWith(tester, [theirMessage('selam', noon)]);

      expect(familyButton(on: true), findsOneWidget);
      expect(familyButton(on: false), findsNothing);
    });

    testWidgets('is hidden when the choice cannot be read', (tester) async {
      matching.familyVisible = const Err(ServerFailure('Okunamadı.'));
      await loadWith(tester, [theirMessage('selam', noon)]);

      expect(familyButton(on: true), findsNothing);
      expect(familyButton(on: false), findsNothing);
    });

    testWidgets('turning the switch on saves it for this match', (
      tester,
    ) async {
      await loadWith(tester, [theirMessage('selam', noon)]);
      await openSheet(tester);
      expect(find.text('Aile görünürlüğü'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(matching.familyVisibleCalls, [(matchId: 'm1', visible: true)]);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(familyButton(on: true), findsOneWidget);
    });

    testWidgets('a failed save puts the switch back and says so', (
      tester,
    ) async {
      matching.familyVisibleResult = const Err(ServerFailure('Kaydedilemedi.'));
      await loadWith(tester, [theirMessage('selam', noon)]);
      await openSheet(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
    });

    testWidgets('the sheet links to the family settings', (tester) async {
      await loadWith(tester, [theirMessage('selam', noon)]);
      await openSheet(tester);

      await tester.tap(find.text('Aile bağlantısını yönet'));
      await tester.pumpAndSettle();

      expect(find.text('aile ayarları'), findsOneWidget);
    });
  });
}
