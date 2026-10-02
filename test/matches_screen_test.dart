import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/preferences/app_preferences.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/matching/domain/entities/match.dart';
import 'package:binasip/features/matching/domain/usecases/get_my_matches.dart';
import 'package:binasip/features/matching/presentation/bloc/matches_cubit.dart';
import 'package:binasip/features/matching/presentation/screens/matches_screen.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_last_messages.dart';
import 'package:binasip/features/messaging/domain/usecases/watch_read_times.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

final _unreadDot = find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == 'Okunmamış mesaj',
);

void main() {
  late FakeMessagingRepository messaging;

  Future<void> pumpList(
    WidgetTester tester, {
    Result<List<Match>>? matches,
    bool showPreviews = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'show_match_message_previews': showPreviews,
    });
    final prefs = AppPreferences(await SharedPreferences.getInstance());
    await prefs.init();
    sl.registerSingleton<AppPreferences>(prefs);
    sl.registerFactory(
      () => MatchesCubit(
        getMyMatches: GetMyMatches(
          FakeMatchingRepository(
            matches ??
                Ok([
                  testMatch('a', DateTime(2026, 1, 1)),
                  testMatch('b', DateTime(2026, 1, 2)),
                ]),
          ),
        ),
        watchLastMessages: WatchLastMessages(messaging),
        watchReadTimes: WatchReadTimes(messaging),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const MatchesScreen()),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await sl.reset();
    messaging = FakeMessagingRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  final tuesday = DateTime(2026, 3, 3, 12);
  final friday = DateTime(2026, 3, 6, 12);

  group('unread indicator', () {
    testWidgets('shows a dot and bold name when their message is unread', (
      tester,
    ) async {
      messaging.previews.add(Ok({'a': theirMessage('selam', friday)}));
      messaging.readTimes.add(const Ok({}));

      await pumpList(tester);

      expect(_unreadDot, findsOneWidget);
      final name = tester.widget<Text>(find.text('Aday a, 27'));
      expect(name.style?.fontWeight, FontWeight.w800);
      expect(
        tester.widget<Text>(find.text('selam')).style?.fontWeight,
        FontWeight.w700,
      );
    });

    testWidgets('no dot once the chat was opened after the message', (
      tester,
    ) async {
      messaging.previews.add(Ok({'a': theirMessage('selam', tuesday)}));
      messaging.readTimes.add(Ok({'a': friday}));

      await pumpList(tester);

      expect(_unreadDot, findsNothing);
      final name = tester.widget<Text>(find.text('Aday a, 27'));
      expect(name.style?.fontWeight, isNot(FontWeight.w800));
    });

    testWidgets('no dot while the read times are still loading', (
      tester,
    ) async {
      messaging.previews.add(Ok({'a': theirMessage('selam', friday)}));

      await pumpList(tester);

      expect(find.text('selam'), findsOneWidget);
      expect(_unreadDot, findsNothing);
    });

    testWidgets('my own latest message is never unread', (tester) async {
      messaging.previews.add(Ok({'a': myMessage('merhaba', friday)}));
      messaging.readTimes.add(const Ok({}));

      await pumpList(tester);

      expect(find.text('Sen: merhaba'), findsOneWidget);
      expect(_unreadDot, findsNothing);
    });

    testWidgets('only the unread row gets the dot', (tester) async {
      messaging.previews.add(
        Ok({
          'a': theirMessage('eski', tuesday),
          'b': theirMessage('yeni', friday),
        }),
      );
      messaging.readTimes.add(Ok({'a': friday}));

      await pumpList(tester);

      expect(_unreadDot, findsOneWidget);
      final dotY = tester.getCenter(_unreadDot).dy;
      expect(
        (dotY - tester.getCenter(find.text('Aday b, 27')).dy).abs(),
        lessThan(20),
      );
    });

    testWidgets('a new incoming message lights the dot up live', (
      tester,
    ) async {
      messaging.previews.add(Ok({'a': theirMessage('selam', tuesday)}));
      messaging.readTimes.add(Ok({'a': friday}));
      await pumpList(tester);
      expect(_unreadDot, findsNothing);

      messaging.previews.add(
        Ok({'a': theirMessage('bir de şu', DateTime(2026, 3, 7, 9))}),
      );
      await tester.pumpAndSettle();

      expect(_unreadDot, findsOneWidget);
      expect(find.text('bir de şu'), findsOneWidget);
    });

    testWidgets('the dot stays when message previews are hidden', (
      tester,
    ) async {
      messaging.previews.add(Ok({'a': theirMessage('gizli metin', friday)}));
      messaging.readTimes.add(const Ok({}));

      await pumpList(tester, showPreviews: false);

      expect(find.text('gizli metin'), findsNothing);
      expect(find.text('İstanbul'), findsWidgets);
      expect(_unreadDot, findsOneWidget);
    });
  });

  group('list states', () {
    testWidgets('most recent activity comes first', (tester) async {
      messaging.previews.add(Ok({'a': theirMessage('en yeni', friday)}));
      messaging.readTimes.add(const Ok({}));

      await pumpList(tester);

      expect(
        tester.getTopLeft(find.text('Aday a, 27')).dy,
        lessThan(tester.getTopLeft(find.text('Aday b, 27')).dy),
      );
    });

    testWidgets('a match without messages invites the first one', (
      tester,
    ) async {
      messaging.previews.add(const Ok({}));
      messaging.readTimes.add(const Ok({}));

      await pumpList(tester);

      expect(find.text('İlk mesajı sen yaz'), findsNWidgets(2));
      expect(_unreadDot, findsNothing);
    });

    testWidgets('shows the empty state with no matches', (tester) async {
      await pumpList(tester, matches: const Ok(<Match>[]));

      expect(find.text('Henüz eşleşmen yok.'), findsOneWidget);
    });

    testWidgets('shows the failure message on error', (tester) async {
      await pumpList(
        tester,
        matches: const Err(ServerFailure('Eşleşmeler yüklenemedi.')),
      );

      expect(find.text('Eşleşmeler yüklenemedi.'), findsOneWidget);
    });
  });
}
