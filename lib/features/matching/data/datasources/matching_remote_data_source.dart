import '../../../../core/error/exceptions.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';

/// **Placeholder data source.** Stands in for Firestore candidate queries
/// + a real matching backend. Seeds a handful of candidates so the
/// discovery feed is runnable before other real users exist — a couple
/// are pre-configured as "already likes you" so a mutual match (FR-4.2)
/// can actually be demonstrated end-to-end. Swap for Firestore without
/// touching `MatchingRepositoryImpl` or anything above it.
abstract interface class MatchingRemoteDataSource {
  Future<List<Candidate>> getCandidates(CandidateFilter filter);
  Future<SwipeOutcome> swipe({required Candidate candidate, required SwipeAction action});
  Future<List<Match>> getMyMatches();
  Future<void> setMatchVisibleToFamily({required String matchId, required bool visible});
}

class MockMatchingRemoteDataSource implements MatchingRemoteDataSource {
  /// FR-4.3.
  static const _dailyLikeLimit = 12;

  int _likesUsedToday = 0;

  /// All matches this account has made, keyed by match id — including
  /// [swipe]-created ones. Seeded with one match from "before this
  /// session" (already marked `visibleToFamily`) so FR-8's guardian view
  /// has something to show without first replaying the whole discovery
  /// flow by hand.
  final Map<String, Match> _myMatches = {
    'match_seed_sena': Match(
      id: 'match_seed_sena',
      candidate: const Candidate(
        id: 'seed_sena',
        name: 'Sena',
        age: 27,
        city: 'İstanbul',
        intent: CandidateIntent.marriage,
        avatarColorSeed: 2,
        bio: 'Eczacı. Ailemle tanışmaktan çekinmem.',
      ),
      matchedAt: DateTime.now().subtract(const Duration(days: 3)),
      visibleToFamily: true,
    ),
  };

  static final List<Candidate> _all = [
    const Candidate(
      id: 'c1',
      name: 'Zeynep',
      age: 28,
      city: 'İstanbul',
      intent: CandidateIntent.marriage,
      avatarColorSeed: 1,
      bio: 'Mimar, çay tiryakisi. Ailemle birlikte yürümeyi tercih ederim.',
    ),
    const Candidate(
      id: 'c2',
      name: 'Elif',
      age: 26,
      city: 'İzmir',
      intent: CandidateIntent.marriage,
      avatarColorSeed: 2,
      bio: 'Öğretmen. Niyetim net: evlilik.',
    ),
    const Candidate(
      id: 'c3',
      name: 'Merve',
      age: 30,
      city: 'Ankara',
      intent: CandidateIntent.notSureYet,
      avatarColorSeed: 3,
      bio: 'Yazılım mühendisi. Süreç içinde netleşsin istiyorum.',
    ),
    const Candidate(
      id: 'c4',
      name: 'Büşra',
      age: 27,
      city: 'İstanbul',
      intent: CandidateIntent.marriage,
      avatarColorSeed: 4,
      bio: 'Diş hekimi. Sakin, aile odaklı biriyim.',
    ),
    const Candidate(
      id: 'c5',
      name: 'Aylin',
      age: 29,
      city: 'Bursa',
      intent: CandidateIntent.marriage,
      avatarColorSeed: 5,
      bio: 'Muhasebeci. Kitap okumayı severim.',
    ),
  ];

  /// Candidates who "already liked you" — swiping `like` on one of these
  /// instantly produces a match, so FR-4.2 is demonstrable without a
  /// second real account.
  static const _alreadyLikedYou = {'c1', 'c4'};

  @override
  Future<List<Candidate>> getCandidates(CandidateFilter filter) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _all.where((c) {
      if (filter.city != null && filter.city!.trim().isNotEmpty) {
        if (c.city.toLowerCase() != filter.city!.trim().toLowerCase()) return false;
      }
      if (filter.minAge != null && c.age < filter.minAge!) return false;
      if (filter.maxAge != null && c.age > filter.maxAge!) return false;
      if (filter.intent != null && c.intent != filter.intent) return false;
      return true;
    }).toList();
  }

  @override
  Future<SwipeOutcome> swipe({required Candidate candidate, required SwipeAction action}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (action == SwipeAction.pass) {
      return const SwipeOutcome(matched: false);
    }

    if (_likesUsedToday >= _dailyLikeLimit) {
      throw const ServerException('Bugünkü beğeni hakkın doldu. Yarın devam edebilirsin.');
    }
    _likesUsedToday++;

    if (_alreadyLikedYou.contains(candidate.id)) {
      final match = Match(
        id: 'match_${candidate.id}',
        candidate: candidate,
        matchedAt: DateTime.now(),
      );
      _myMatches[match.id] = match;
      return SwipeOutcome(matched: true, match: match);
    }
    return const SwipeOutcome(matched: false);
  }

  @override
  Future<List<Match>> getMyMatches() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _myMatches.values.toList()..sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
  }

  @override
  Future<void> setMatchVisibleToFamily({required String matchId, required bool visible}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final existing = _myMatches[matchId];
    if (existing == null) {
      throw const ServerException('Eşleşme bulunamadı.');
    }
    _myMatches[matchId] = existing.copyWith(visibleToFamily: visible);
  }
}
