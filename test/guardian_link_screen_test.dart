import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/family/domain/entities/guardian_link.dart';
import 'package:binasip/features/family/domain/entities/relationship.dart';
import 'package:binasip/features/family/domain/usecases/get_guardian_link.dart';
import 'package:binasip/features/family/domain/usecases/get_linked_single_name.dart';
import 'package:binasip/features/family/domain/usecases/get_visible_matches.dart';
import 'package:binasip/features/family/domain/usecases/link_guardian.dart';
import 'package:binasip/features/family/presentation/bloc/current_link_cubit.dart';
import 'package:binasip/features/family/presentation/bloc/guardian_cubit.dart';
import 'package:binasip/features/family/presentation/screens/guardian_link_screen.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

const _linkedToDeniz = GuardianLink(
  guardianName: 'Mehmet',
  relationship: Relationship.baba,
  singleName: 'Deniz',
);

void main() {
  late FakeFamilyRepository repo;

  /// The link screen, opened by address (nothing underneath, as at the end
  /// of a guardian's registration) or pushed from a stand-in settings page.
  Future<void> pumpLink(
    WidgetTester tester, {
    bool fromSettings = false,
  }) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    sl.registerFactory(
      () => CurrentLinkCubit(getGuardianLink: GetGuardianLink(repo)),
    );
    final auth = await signedInAuthCubit(testGuardianUser);
    addTearDown(auth.close);
    final guardian = GuardianCubit(
      linkGuardian: LinkGuardian(repo),
      getVisibleMatches: GetVisibleMatches(repo),
      getLinkedSingleName: GetLinkedSingleName(repo),
    );
    addTearDown(guardian.close);

    final router = GoRouter(
      initialLocation: fromSettings ? '/settings' : '/guardian/link',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/guardian/link'),
              child: const Text('ayarlar'),
            ),
          ),
        ),
        GoRoute(
          path: '/guardian/link',
          builder: (_, _) => const GuardianLinkScreen(),
        ),
        GoRoute(
          path: '/guardian/home',
          builder: (_, _) => const Scaffold(body: Text('veli ana ekranı')),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: guardian),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    if (fromSettings) await tester.tap(find.text('ayarlar'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> press(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  bool onLinkScreen() => find.byType(GuardianLinkScreen).evaluate().isNotEmpty;

  setUp(() async {
    await sl.reset();
    repo = FakeFamilyRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('first link (FR-8.2/8.3)', () {
    testWidgets('is the plain form, with nowhere to go back to', (
      tester,
    ) async {
      await pumpLink(tester);

      expect(find.text('Yakınının hesabına bağlan.'), findsOneWidget);
      expect(find.text('Bağlan'), findsOneWidget);
      expect(field('AİLE KODU'), findsOneWidget);
      expect(find.text('Şu an bağlı olduğun hesap'), findsNothing);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('links straight away and opens the home screen', (
      tester,
    ) async {
      await pumpLink(tester);

      await tester.enterText(field('ADIN'), 'Mehmet');
      await tester.tap(find.text('Baba'));
      await tester.enterText(field('AİLE KODU'), 'ABCD1234');
      await press(tester, 'Bağlan');

      expect(repo.linkCalls.single, (
        name: 'Mehmet',
        relationship: Relationship.baba,
        code: 'ABCD1234',
      ));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('veli ana ekranı'), findsOneWidget);
    });

    testWidgets('needs a name, a relationship and a code', (tester) async {
      await pumpLink(tester);

      await press(tester, 'Bağlan');

      expect(
        find.text('Ad, yakınlık derecesi ve aile kodu zorunlu.'),
        findsOneWidget,
      );
      expect(repo.linkCalls, isEmpty);
    });

    testWidgets('a link that cannot be read is treated as none', (
      tester,
    ) async {
      repo.currentLink = const Err(ServerFailure('Bağlı hesap okunamadı.'));
      await pumpLink(tester);

      expect(find.text('Yakınının hesabına bağlan.'), findsOneWidget);
    });
  });

  // FR-8.3: one account at a time - a new link replaces the old one.
  group('changing the linked account', () {
    setUp(() => repo.currentLink = const Ok(_linkedToDeniz));

    testWidgets('says whose account is linked now and what will happen', (
      tester,
    ) async {
      await pumpLink(tester);

      expect(find.text('Bağlı hesabı değiştir.'), findsOneWidget);
      expect(find.text('Şu an bağlı olduğun hesap'), findsOneWidget);
      expect(find.text('Deniz'), findsOneWidget);
      expect(find.textContaining('şimdiki bağlantın kalkar'), findsOneWidget);
      expect(find.text('Bağlantıyı değiştir'), findsOneWidget);
      expect(field('YENİ AİLE KODU'), findsOneWidget);
    });

    testWidgets('starts from the name and relationship already given', (
      tester,
    ) async {
      await pumpLink(tester);

      expect(
        tester.widget<TextField>(field('ADIN')).controller!.text,
        'Mehmet',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Baba'))
            .selected,
        isTrue,
      );
    });

    testWidgets('asks first; "Vazgeç" changes nothing', (tester) async {
      await pumpLink(tester);
      await tester.enterText(field('YENİ AİLE KODU'), 'WXYZ5678');

      await press(tester, 'Bağlantıyı değiştir');
      expect(find.text('Bağlantı değişsin mi?'), findsOneWidget);
      expect(find.textContaining('Deniz ile bağlantın kalkar'), findsOneWidget);
      expect(repo.linkCalls, isEmpty);

      await press(tester, 'Vazgeç');

      expect(repo.linkCalls, isEmpty);
      expect(onLinkScreen(), isTrue);
    });

    testWidgets('"Değiştir" links to the new account and opens home', (
      tester,
    ) async {
      await pumpLink(tester);
      await tester.enterText(field('YENİ AİLE KODU'), 'WXYZ5678');

      await press(tester, 'Bağlantıyı değiştir');
      await press(tester, 'Değiştir');

      expect(repo.linkCalls.single, (
        name: 'Mehmet',
        relationship: Relationship.baba,
        code: 'WXYZ5678',
      ));
      expect(find.text('veli ana ekranı'), findsOneWidget);
    });

    testWidgets('a code that is not accepted keeps the screen, with why', (
      tester,
    ) async {
      repo.linkResult = const Err(ServerFailure('Bu aile kodu geçerli değil.'));
      await pumpLink(tester);
      await tester.enterText(field('YENİ AİLE KODU'), 'YANLIS00');

      await press(tester, 'Bağlantıyı değiştir');
      await press(tester, 'Değiştir');

      expect(find.text('Bu aile kodu geçerli değil.'), findsOneWidget);
      expect(onLinkScreen(), isTrue);
    });

    testWidgets('without a new code nothing is asked', (tester) async {
      await pumpLink(tester);

      await press(tester, 'Bağlantıyı değiştir');

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('Ad, yakınlık derecesi ve aile kodu zorunlu.'),
        findsOneWidget,
      );
    });

    testWidgets('an account whose name cannot be read is still named', (
      tester,
    ) async {
      repo.currentLink = const Ok(
        GuardianLink(guardianName: 'Mehmet', relationship: Relationship.baba),
      );
      await pumpLink(tester);
      expect(find.text('Adı okunamadı'), findsOneWidget);

      await tester.enterText(field('YENİ AİLE KODU'), 'WXYZ5678');
      await press(tester, 'Bağlantıyı değiştir');

      expect(
        find.textContaining('Şimdiki hesap ile bağlantın kalkar'),
        findsOneWidget,
      );
    });

    testWidgets('opened by address, back goes to the home screen', (
      tester,
    ) async {
      await pumpLink(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('veli ana ekranı'), findsOneWidget);
      expect(repo.linkCalls, isEmpty);
    });

    testWidgets('opened from settings, back returns there', (tester) async {
      await pumpLink(tester, fromSettings: true);
      expect(find.text('Bağlı hesabı değiştir.'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('ayarlar'), findsOneWidget);
    });
  });
}
