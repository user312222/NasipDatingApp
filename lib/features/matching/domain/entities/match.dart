import 'package:equatable/equatable.dart';

import 'candidate.dart';

/// FR-4.2: created the moment a like becomes mutual.
class Match extends Equatable {
  const Match({
    required this.id,
    required this.candidate,
    required this.matchedAt,
    this.visibleToFamily = false,
  });

  final String id;
  final Candidate candidate;
  final DateTime matchedAt;

  /// FR-8.4: opt-in, per-match, default off. A linked guardian (FR-8.5)
  /// can only ever see matches where this is true.
  final bool visibleToFamily;

  Match copyWith({bool? visibleToFamily}) => Match(
    id: id,
    candidate: candidate,
    matchedAt: matchedAt,
    visibleToFamily: visibleToFamily ?? this.visibleToFamily,
  );

  @override
  List<Object?> get props => [id, candidate, matchedAt, visibleToFamily];
}
