import 'package:equatable/equatable.dart';

/// Mirrors `ProfileIntent` from the profile feature — duplicated
/// deliberately (rather than importing across features) to keep
/// `matching`'s domain layer independent of `profile`'s; only these two
/// stable, rarely-changing labels are shared between them.
enum CandidateIntent { marriage, notSureYet }

/// A read-only view of another user's profile, as shown in the discovery
/// feed. `avatarColorSeed` stands in for a real photo — see
/// `MockMatchingRemoteDataSource` — until photo upload/download (FR-2.1)
/// is wired to real storage.
class Candidate extends Equatable {
  const Candidate({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.intent,
    required this.avatarColorSeed,
    this.bio,
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final CandidateIntent intent;
  final int avatarColorSeed;
  final String? bio;

  @override
  List<Object?> get props => [id, name, age, city, intent, avatarColorSeed, bio];
}
