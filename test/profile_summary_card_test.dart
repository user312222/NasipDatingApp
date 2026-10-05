import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/profile/data/models/profile_model.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/usecases/get_profile.dart';
import 'package:binasip/features/profile/presentation/bloc/profile_summary_cubit.dart';
import 'package:binasip/features/profile/presentation/widgets/profile_summary_card.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

const _hint =
    'Adını, şehrini, niyetini, hakkındaki bilgileri ve '
    'fotoğraf görünürlüğünü buradan güncelleyebilirsin.';

void main() {
  late FakeProfileRepository repo;

  // As the real repository hands it out: the data layer's model.
  Result<Profile?> stored(Profile profile) =>
      Ok(ProfileModel.fromEntity(profile));

  ProfileSummaryCubit cubit() =>
      ProfileSummaryCubit(getProfile: GetProfile(repo));

  /// The card on a stand-in for the Hesap tab, with a stand-in edit screen
  /// that can only be closed.
  Future<void> pumpCard(WidgetTester tester, {bool enabled = true}) async {
    sl.registerFactory(cubit);
    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (_, _) => Scaffold(
            body: ProfileSummaryCard(userId: 'me', enabled: enabled),
          ),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('düzenleme ekranı'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  OutlinedButton editButton(WidgetTester tester) =>
      tester.widget(find.bySubtype<OutlinedButton>());

  setUp(() async {
    await sl.reset();
    repo = FakeProfileRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('the card', () {
    testWidgets('shows name, age and city once the profile is read', (
      tester,
    ) async {
      repo.stored = stored(testProfile());
      await pumpCard(tester);

      expect(find.text('Zeynep, 27'), findsOneWidget);
      expect(find.text('İstanbul'), findsOneWidget);
      // The avatar: the initial, as others see it in lists.
      expect(find.text('Z'), findsOneWidget);
      expect(find.text(_hint), findsNothing);
    });

    testWidgets('says what the button is for when there is no profile', (
      tester,
    ) async {
      await pumpCard(tester);

      expect(find.text(_hint), findsOneWidget);
      expect(editButton(tester).onPressed, isNotNull);
    });

    testWidgets('a failed read leaves the card as it was, button included', (
      tester,
    ) async {
      repo.stored = const Err(ServerFailure('Profilin yüklenemedi.'));
      await pumpCard(tester);

      expect(find.text(_hint), findsOneWidget);
      // The edit screen is where a failed read is reported.
      expect(find.text('Profilin yüklenemedi.'), findsNothing);
      expect(editButton(tester).onPressed, isNotNull);
    });

    testWidgets('the button opens the edit screen', (tester) async {
      repo.stored = stored(testProfile());
      await pumpCard(tester);

      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();

      expect(find.text('düzenleme ekranı'), findsOneWidget);
    });

    testWidgets('coming back shows what was saved there', (tester) async {
      repo.stored = stored(testProfile());
      await pumpCard(tester);
      await tester.tap(find.text('Profili düzenle'));
      await tester.pumpAndSettle();

      // What a save on the edit screen leaves behind.
      repo.stored = stored(
        Profile(
          userId: 'me',
          name: 'Zeynep Ada',
          birthDate: testProfile().birthDate,
          city: 'Ankara',
          intent: ProfileIntent.marriage,
          photoRefs: const ['photo_0.jpg'],
          familyInvolvementOptIn: false,
        ),
      );
      await tester.tap(find.text('düzenleme ekranı'));
      await tester.pumpAndSettle();

      expect(find.text('Zeynep Ada, 27'), findsOneWidget);
      expect(find.text('Ankara'), findsOneWidget);
      expect(find.text('İstanbul'), findsNothing);
    });

    testWidgets('is switched off while the account is being closed', (
      tester,
    ) async {
      repo.stored = stored(testProfile());
      await pumpCard(tester, enabled: false);

      expect(editButton(tester).onPressed, isNull);
      // Still says whose account this is.
      expect(find.text('Zeynep, 27'), findsOneWidget);
    });
  });

  group('the cubit', () {
    test('knows nothing until the profile is read', () {
      final c = cubit();
      addTearDown(c.close);

      expect(c.state, isNull);
    });

    test('a failed read after a good one keeps what was shown', () async {
      final c = cubit();
      addTearDown(c.close);
      repo.stored = stored(testProfile());
      await c.load('me');

      repo.stored = const Err(ServerFailure('Profilin yüklenemedi.'));
      await c.load('me');

      expect(c.state?.name, 'Zeynep');
    });

    test('closing while reading does not emit', () async {
      final c = cubit();
      repo.stored = stored(testProfile());
      final reading = c.load('me');

      await c.close();
      await reading;

      expect(c.isClosed, isTrue);
    });
  });
}
