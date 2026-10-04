import '../../../../core/error/exceptions.dart';
import '../../../matching/data/datasources/matching_remote_data_source.dart';
import '../../../matching/domain/entities/candidate.dart';
import '../../domain/entities/family_visible_match.dart';
import '../../domain/entities/relationship.dart';

/// **Placeholder data source.** Stands in for Firestore — a guardian's
/// query there would just be `matches.where(visibleToFamily == true)` on
/// the linked single user's matches, so it's realistic (and fine, at the
/// *data* layer only) for this mock to read the same in-memory store as
/// `MockMatchingRemoteDataSource`. The wall FR-8.6 requires is at the
/// domain/presentation layers: nothing guardian-facing ever imports
/// `MatchingRepository`, `Match`, or `Candidate` — only the stripped
/// [FamilyVisibleMatch] comes out of here.
abstract interface class FamilyRemoteDataSource {
  Future<void> linkGuardian({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  });
  Future<List<FamilyVisibleMatch>> getVisibleMatches(String guardianUserId);
  Future<String> getOrCreateInviteCode(String singleUserId);
}

class MockFamilyRemoteDataSource implements FamilyRemoteDataSource {
  MockFamilyRemoteDataSource(this._matching);

  final MatchingRemoteDataSource _matching;

  /// Fixed for the demo — a real backend mints a unique, expiring code
  /// (FR-8.3: ~7 days, regenerable).
  static const _demoCode = 'AILE1234';

  final Set<String> _linkedGuardians = {};

  @override
  Future<String> getOrCreateInviteCode(String singleUserId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demoCode;
  }

  @override
  Future<void> linkGuardian({
    required String guardianUserId,
    required String guardianName,
    required Relationship relationship,
    required String inviteCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (inviteCode.trim().toUpperCase() != _demoCode) {
      throw const ServerException('Bu aile kodu geçerli değil.');
    }
    _linkedGuardians.add(guardianUserId);
  }

  @override
  Future<List<FamilyVisibleMatch>> getVisibleMatches(
    String guardianUserId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!_linkedGuardians.contains(guardianUserId)) {
      throw const ServerException('Önce bir hesaba bağlanmalısın.');
    }
    final matches = await _matching.getMyMatches();
    return matches
        .where((m) => m.visibleToFamily)
        .map(
          (m) => FamilyVisibleMatch(
            candidateName: m.candidate.name,
            candidateAge: m.candidate.age,
            candidateCity: m.candidate.city,
            intentLabel: m.candidate.intent == CandidateIntent.marriage
                ? 'Evlilik'
                : 'Henüz emin değil',
            statusLabel: DateTime.now().difference(m.matchedAt).inDays < 1
                ? 'Yeni eşleşme'
                : 'Aktif yazışıyorlar',
            matchedAt: m.matchedAt,
          ),
        )
        .toList();
  }
}
