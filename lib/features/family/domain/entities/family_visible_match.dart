import 'package:equatable/equatable.dart';

/// FR-8.5: the *entire* shape a guardian is ever allowed to see. No
/// message content, no photo, no contact info — deliberately its own
/// minimal type rather than `matching`'s `Match`/`Candidate`, so a
/// guardian screen can never accidentally end up holding (and rendering)
/// more than this by construction.
class FamilyVisibleMatch extends Equatable {
  const FamilyVisibleMatch({
    required this.candidateName,
    required this.candidateAge,
    required this.candidateCity,
    required this.statusLabel,
    required this.matchedAt,
  });

  final String candidateName;
  final int candidateAge;
  final String candidateCity;

  /// FR-8.5: a coarse, human-readable status — e.g. "Yeni eşleşme",
  /// "Aktif yazışıyorlar" — never a message count or transcript.
  final String statusLabel;

  final DateTime matchedAt;

  @override
  List<Object?> get props => [candidateName, candidateAge, candidateCity, statusLabel, matchedAt];
}
