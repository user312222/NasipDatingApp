import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/family/domain/entities/family_visible_match.dart';
import 'package:binasip/features/family/domain/entities/relationship.dart';
import 'package:binasip/features/family/domain/usecases/get_linked_single_name.dart';
import 'package:binasip/features/family/domain/usecases/get_visible_matches.dart';
import 'package:binasip/features/family/domain/usecases/link_guardian.dart';
import 'package:binasip/features/family/presentation/bloc/guardian_cubit.dart';

import 'support/fakes.dart';

final _shared = FamilyVisibleMatch(
  candidateName: 'Zeynep',
  candidateAge: 27,
  candidateCity: 'İstanbul',
  intentLabel: 'Evlilik',
  statusLabel: 'Yeni eşleşme',
  matchedAt: DateTime(2026, 9, 1),
);

void main() {
  late FakeFamilyRepository repo;

  GuardianCubit cubit() => GuardianCubit(
    linkGuardian: LinkGuardian(repo),
    getVisibleMatches: GetVisibleMatches(repo),
    getLinkedSingleName: GetLinkedSingleName(repo),
  );

  setUp(() => repo = FakeFamilyRepository());

  group('loadMatches', () {
    test('loads the shared matches with the linked name', () async {
      repo.matches = Ok([_shared]);
      repo.singleName = const Ok('Deniz');
      final c = cubit();

      await c.loadMatches('guardian');

      expect(c.state, GuardianMatchesLoaded([_shared], singleName: 'Deniz'));
    });

    test('still shows the matches when the name cannot be read', () async {
      repo.matches = Ok([_shared]);
      repo.singleName = const Err(ServerFailure('Bağlı hesap okunamadı.'));
      final c = cubit();

      await c.loadMatches('guardian');

      expect(c.state, GuardianMatchesLoaded([_shared]));
    });

    test('has no name when the linked account has no public profile', () async {
      final c = cubit();

      await c.loadMatches('guardian');

      final state = c.state as GuardianMatchesLoaded;
      expect(state.matches, isEmpty);
      expect(state.singleName, isNull);
    });

    test('a failed match list fails the screen, name or not', () async {
      repo.matches = const Err(ServerFailure('Önce bir hesaba bağlanmalısın.'));
      repo.singleName = const Ok('Deniz');
      final c = cubit();

      await c.loadMatches('guardian');

      expect(
        c.state,
        const GuardianMatchesFailed('Önce bir hesaba bağlanmalısın.'),
      );
    });

    test('closing while loading does not emit', () async {
      final c = cubit();
      final loading = c.loadMatches('guardian');

      await c.close();
      await loading;

      expect(c.isClosed, isTrue);
    });
  });

  group('link', () {
    test('reports success', () async {
      final c = cubit();

      await c.link(
        guardianUserId: 'guardian',
        guardianName: 'Mehmet',
        relationship: Relationship.values.first,
        inviteCode: 'ABCD1234',
      );

      expect(c.state, const GuardianLinked());
    });

    test('surfaces an invalid code', () async {
      repo.linkResult = const Err(ServerFailure('Bu aile kodu geçerli değil.'));
      final c = cubit();

      await c.link(
        guardianUserId: 'guardian',
        guardianName: 'Mehmet',
        relationship: Relationship.values.first,
        inviteCode: 'YANLIS',
      );

      expect(c.state, const GuardianLinkFailed('Bu aile kodu geçerli değil.'));
    });
  });
}
