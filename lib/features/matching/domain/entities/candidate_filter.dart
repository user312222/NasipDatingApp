import 'package:equatable/equatable.dart';

import 'candidate.dart';

/// FR-4.1: the discovery feed's filters. Everything optional/nullable —
/// an unset field means "don't filter on this."
///
/// Note on "dil" (language): with no multi-language profiles yet (v1 is
/// Türkçe-only per REQUIREMENTS.md §6), there's nothing to filter by —
/// this field is wired through the repository interface now so it isn't
/// a breaking change later, but the mock data source ignores it.
class CandidateFilter extends Equatable {
  const CandidateFilter({this.city, this.minAge, this.maxAge, this.intent, this.language});

  final String? city;
  final int? minAge;
  final int? maxAge;
  final CandidateIntent? intent;
  final String? language;

  static const empty = CandidateFilter();

  CandidateFilter copyWith({
    String? city,
    int? minAge,
    int? maxAge,
    CandidateIntent? intent,
    String? language,
    bool clearCity = false,
    bool clearIntent = false,
  }) {
    return CandidateFilter(
      city: clearCity ? null : (city ?? this.city),
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      intent: clearIntent ? null : (intent ?? this.intent),
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [city, minAge, maxAge, intent, language];
}
