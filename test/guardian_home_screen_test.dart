import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/family/domain/entities/family_visible_match.dart';
import 'package:binasip/features/family/domain/entities/relationship.dart';
import 'package:binasip/features/family/domain/usecases/get_linked_single_name.dart';
import 'package:binasip/features/family/domain/usecases/get_visible_matches.dart';
import 'package:binasip/features/family/domain/usecases/link_guardian.dart';
import 'package:binasip/features/family/presentation/bloc/guardian_cubit.dart';
import 'package:binasip/features/family/presentation/screens/guardian_home_screen.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

FamilyVisibleMatch _match(String name) => FamilyVisibleMatch(
  candidateName: name,
  candidateAge: 27,
  candidateCity: 'İstanbul',
  intentLabel: 'Evlilik',
  statusLabel: 'Yeni eşleşme',
  matchedAt: DateTime(2026, 9, 1),
);

void main() {
  late FakeFamilyRepository repo;
  late GuardianCubit guardian;

  Future<void> pumpHome(WidgetTester tester) async {
    final auth = await signedInAuthCubit(testGuardianUser);
    addTearDown(auth.close);
    guardian = GuardianCubit(
      linkGuardian: LinkGuardian(repo),
      getVisibleMatches: GetVisibleMatches(repo),
      getLinkedSingleName: GetLinkedSingleName(repo),
    );
    addTearDown(guardian.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: guardian),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const GuardianHomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// What the link screen does when it sits on top of this one.
  Future<void> linkOnTop(WidgetTester tester) async {
    await guardian.link(
      guardianUserId: testGuardianUser.id,
      guardianName: 'Mehmet',
      relationship: Relationship.baba,
      inviteCode: 'WXYZ5678',
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = FakeFamilyRepository()
      ..matches = Ok([_match('Zeynep')])
      ..singleName = const Ok('Deniz');
  });

  testWidgets('says whose matches these are', (tester) async {
    await pumpHome(tester);

    expect(find.text('Deniz 1 eşleşme paylaştı'), findsOneWidget);
    expect(find.text('Zeynep, 27'), findsOneWidget);
  });

  // The link screen shares this screen's cubit and is opened on top of it
  // to change the linked account.
  group('when the linked account is changed on top of it', () {
    testWidgets('shows the new account, not a spinner', (tester) async {
      await pumpHome(tester);
      repo
        ..matches = Ok([_match('Elif'), _match('Selin')])
        ..singleName = const Ok('Ayşe');

      await linkOnTop(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Ayşe 2 eşleşme paylaştı'), findsOneWidget);
      expect(find.text('Elif, 27'), findsOneWidget);
      expect(find.text('Zeynep, 27'), findsNothing);
    });

    testWidgets('a failed attempt leaves the list as it was', (tester) async {
      await pumpHome(tester);
      repo.linkResult = const Err(ServerFailure('Bu aile kodu geçerli değil.'));

      await linkOnTop(tester);

      expect(find.text('Deniz 1 eşleşme paylaştı'), findsOneWidget);
      expect(find.text('Zeynep, 27'), findsOneWidget);
      // Not the "nothing shared yet" card the bare link state would give.
      expect(find.text('Henüz paylaşılan eşleşme yok'), findsNothing);
    });
  });
}
