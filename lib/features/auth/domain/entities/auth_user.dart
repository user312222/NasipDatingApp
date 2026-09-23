import 'package:equatable/equatable.dart';

import 'account_type.dart';

/// The signed-in user, from the onboarding flow's point of view.
///
/// Deliberately carries only `verifiedAt` (a timestamp), never raw
/// selfie/biometric data — per REQUIREMENTS.md FR-7.2, verification
/// evidence is processed entirely by the third-party vendor and never
/// touches Bi Nasip's own storage.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.phone,
    this.accountType = AccountType.single,
    this.verifiedAt,
  });

  final String id;
  final String phone;
  final AccountType accountType;
  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;

  AuthUser copyWith({
    AccountType? accountType,
    DateTime? verifiedAt,
    bool clearVerifiedAt = false,
  }) => AuthUser(
    id: id,
    phone: phone,
    accountType: accountType ?? this.accountType,
    verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
  );

  @override
  List<Object?> get props => [id, phone, accountType, verifiedAt];
}
