import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/feed/domain/entities/feed_post.dart';
import 'package:binasip/features/feed/domain/usecases/delete_my_answer.dart';
import 'package:binasip/features/feed/domain/usecases/set_post_liked.dart';
import 'package:binasip/features/feed/domain/usecases/submit_answer.dart';
import 'package:binasip/features/feed/domain/usecases/watch_feed.dart';
import 'package:binasip/features/feed/presentation/bloc/feed_cubit.dart';
import 'package:binasip/features/feed/presentation/screens/feed_screen.dart';
import 'package:binasip/features/safety/domain/usecases/block_user.dart';
import 'package:binasip/features/safety/domain/usecases/report_user.dart';
import 'package:binasip/features/safety/presentation/bloc/safety_cubit.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

void main() {
  late FakeFeedRepository repo;

  Future<void> pumpFeed(WidgetTester tester, [List<FeedPost>? posts]) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    sl.registerFactory(
      () => FeedCubit(
        watchFeed: WatchFeed(repo),
        submitAnswer: SubmitAnswer(repo),
        deleteMyAnswer: DeleteMyAnswer(repo),
        setPostLiked: SetPostLiked(repo),
      ),
    );
    final safety = FakeSafetyRepository();
    sl.registerFactory(
      () => SafetyCubit(
        reportUser: ReportUser(safety),
        blockUser: BlockUser(safety),
      ),
    );
    if (posts != null) repo.feeds.add(Ok(testFeed(posts)));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const FeedScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() async {
    await sl.reset();
    repo = FakeFeedRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows a spinner until the feed arrives', (tester) async {
    await pumpFeed(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the question, the composer and who will see it', (
    tester,
  ) async {
    await pumpFeed(tester, []);

    expect(find.text(testQuestion.text), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('tüm üyelere görünür'), findsOneWidget);
    expect(
      find.text('Henüz kimse cevap vermedi. İlk cevabı sen yaz.'),
      findsOneWidget,
    );
  });

  testWidgets('lists other members with name, age, city and like count', (
    tester,
  ) async {
    await pumpFeed(tester, [
      testPost('a', text: 'Uzun bir kahvaltı.', likeCount: 3),
      testPost('b', text: 'Kitap ve çay.'),
    ]);

    expect(find.text('Diğer cevaplar (2)'), findsOneWidget);
    expect(find.text('Üye a, 28'), findsOneWidget);
    expect(find.text('Uzun bir kahvaltı.'), findsOneWidget);
    expect(find.text('Kitap ve çay.'), findsOneWidget);
    expect(find.textContaining('Ankara'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('sharing sends the answer and clears the field', (tester) async {
    await pumpFeed(tester, []);

    await tester.enterText(find.byType(TextField), '  Yürüyüş ve çay.  ');
    await tester.pump();
    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    expect(repo.submitted, ['Yürüyüş ve çay.']);

    repo.pendingSubmit!.complete(const Ok(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('the share button stays inactive until something is typed', (
    tester,
  ) async {
    await pumpFeed(tester, []);

    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    expect(repo.submitted, isEmpty);

    await tester.enterText(find.byType(TextField), 'Merhaba');
    await tester.pump();
    expect(find.text('7/280'), findsOneWidget);
  });

  testWidgets('a failed share shows a SnackBar and keeps what was typed', (
    tester,
  ) async {
    await pumpFeed(tester, []);

    await tester.enterText(find.byType(TextField), 'Yürüyüş ve çay.');
    await tester.pump();
    await tester.tap(find.text('Paylaş'));
    await tester.pump();
    repo.pendingSubmit!.complete(
      const Err(ServerFailure('Cevabın paylaşılamadı.')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cevabın paylaşılamadı.'), findsOneWidget);
    expect(find.text('Yürüyüş ve çay.'), findsOneWidget);
  });

  testWidgets('after answering, my answer replaces the composer', (
    tester,
  ) async {
    await pumpFeed(tester, [
      testPost('me', isMine: true, text: 'Benim cevabım.', likeCount: 2),
      testPost('a'),
    ]);

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Senin cevabın'), findsOneWidget);
    expect(find.text('Benim cevabım.'), findsOneWidget);
    expect(find.text('2 beğeni'), findsOneWidget);
    expect(find.text('Diğer cevaplar (1)'), findsOneWidget);
  });

  testWidgets('I can delete my answer', (tester) async {
    await pumpFeed(tester, [testPost('me', isMine: true)]);

    await tester.tap(find.text('Sil'));
    await tester.pump();

    expect(repo.deleteCalls, 1);
  });

  testWidgets('tapping the heart likes, tapping a liked one un-likes', (
    tester,
  ) async {
    await pumpFeed(tester, [
      testPost('a'),
      testPost('b', likedByMe: true, likeCount: 1),
    ]);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump();

    expect(repo.likeCalls, [
      (postId: 'a_2026-3-6', liked: true),
      (postId: 'b_2026-3-6', liked: false),
    ]);
  });

  testWidgets('a new answer appears live', (tester) async {
    await pumpFeed(tester, [testPost('a')]);
    expect(find.text('cevap b'), findsNothing);

    repo.feeds.add(Ok(testFeed([testPost('a'), testPost('b')])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('cevap b'), findsOneWidget);
  });

  testWidgets('shows the failure when the feed cannot load', (tester) async {
    repo.feeds.add(const Err(ServerFailure('Akış yüklenemedi.')));
    await pumpFeed(tester);

    expect(find.text('Akış yüklenemedi.'), findsOneWidget);
  });
}
