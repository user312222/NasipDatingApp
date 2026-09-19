import 'package:equatable/equatable.dart';

/// A single early-access sign-up. Pure domain object — no JSON, no
/// Firestore, no UI concerns.
class WaitlistEntry extends Equatable {
  const WaitlistEntry({required this.name, required this.contact, this.city});

  final String name;

  /// Email or phone number — the landing page treats these as one field
  /// (FR references "e-posta veya telefon"); split into two typed fields
  /// once the backend needs to disambiguate for invite delivery.
  final String contact;

  final String? city;

  @override
  List<Object?> get props => [name, contact, city];
}
