import 'package:equatable/equatable.dart';

import 'relationship.dart';

/// What a guardian is linked to right now, and as whom (FR-8.2/8.3: one
/// account at a time).
class GuardianLink extends Equatable {
  const GuardianLink({
    required this.guardianName,
    required this.relationship,
    this.singleName,
  });

  /// The name and relationship the guardian gave when linking.
  final String guardianName;
  final Relationship relationship;

  /// The linked account's first name. Null when that account has no public
  /// profile (yet, or any more) - the link is there all the same.
  final String? singleName;

  @override
  List<Object?> get props => [guardianName, relationship, singleName];
}
