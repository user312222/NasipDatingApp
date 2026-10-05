import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/family/domain/entities/guardian_link.dart';
import 'package:binasip/features/family/domain/entities/relationship.dart';
import 'package:binasip/features/family/domain/usecases/get_guardian_link.dart';
import 'package:binasip/features/family/presentation/bloc/current_link_cubit.dart';
import 'package:binasip/features/family/presentation/widgets/guardian_link_card.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

const _linkedToDeniz = GuardianLink(
  guardianName: 'Mehmet',
  relationship: Relationship.baba,
  singleName: 'Deniz',
);

void main() {
  late FakeFamilyRepository repo;

  CurrentLinkCubit cubit() =>
      CurrentLinkCubit(getGuardianLink: GetGuardianLink(repo));

  /// The card on a stand-in for the guardian's settings screen.
  Future<void> pumpCard(WidgetTester tester, {bool enabled = true}) async {
    sl.registerFactory(cubit);
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => Scaffold(
            body: GuardianLinkCard(userId: 'guardian', enabled: enabled),
          ),
        ),
        GoRoute(
          path: '/guardian/link',
          builder: (_, _) => const Scaffold(body: Text('bağlanma ekranı')),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  OutlinedButton button(WidgetTester tester) =>
      tester.widget(find.bySubtype<OutlinedButton>());

  setUp(() async {
    await sl.reset();
    repo = FakeFamilyRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('the card', () {
    testWidgets('says whose account is followed, and as whom', (tester) async {
      repo.currentLink = const Ok(_linkedToDeniz);
      await pumpCard(tester);

      expect(find.text('Deniz'), findsOneWidget);
      expect(find.text('Yakınlığın: Baba'), findsOneWidget);
      expect(
        find.textContaining('Aynı anda yalnızca bir hesaba'),
        findsOneWidget,
      );
      expect(find.text('Bağlı hesabı değiştir'), findsOneWidget);
    });

    testWidgets('opens the link screen', (tester) async {
      repo.currentLink = const Ok(_linkedToDeniz);
      await pumpCard(tester);

      await tester.tap(find.text('Bağlı hesabı değiştir'));
      await tester.pumpAndSettle();

      expect(find.text('bağlanma ekranı'), findsOneWidget);
    });

    testWidgets('offers to link when there is no link yet', (tester) async {
      await pumpCard(tester);

      expect(
        find.textContaining('Henüz bir hesaba bağlı değilsin'),
        findsOneWidget,
      );
      expect(find.text('Bir hesaba bağlan'), findsOneWidget);
      expect(find.textContaining('Yakınlığın'), findsNothing);
    });

    testWidgets('a linked account without a readable name is still shown', (
      tester,
    ) async {
      repo.currentLink = const Ok(
        GuardianLink(guardianName: 'Mehmet', relationship: Relationship.teyze),
      );
      await pumpCard(tester);

      expect(find.text('Adı okunamadı'), findsOneWidget);
      expect(find.text('Yakınlığın: Teyze'), findsOneWidget);
    });

    testWidgets('is switched off while the account is being closed', (
      tester,
    ) async {
      repo.currentLink = const Ok(_linkedToDeniz);
      await pumpCard(tester, enabled: false);

      expect(button(tester).onPressed, isNull);
    });
  });

  group('the cubit', () {
    test('does not know until it has asked', () {
      final c = cubit();
      addTearDown(c.close);

      expect(c.state, const CurrentLinkLoading());
    });

    test('finds the link', () async {
      final c = cubit();
      addTearDown(c.close);
      repo.currentLink = const Ok(_linkedToDeniz);

      await c.load('guardian');

      expect(c.state, const CurrentLinkFound(_linkedToDeniz));
    });

    test('no link, or a link that cannot be read, is "none"', () async {
      final c = cubit();
      addTearDown(c.close);

      await c.load('guardian');
      expect(c.state, const CurrentLinkNone());

      repo.currentLink = const Err(ServerFailure('Bağlı hesap okunamadı.'));
      await c.load('guardian');
      expect(c.state, const CurrentLinkNone());
    });

    test('closing while asking does not emit', () async {
      final c = cubit();
      final asking = c.load('guardian');

      await c.close();
      await asking;

      expect(c.isClosed, isTrue);
    });
  });
}
