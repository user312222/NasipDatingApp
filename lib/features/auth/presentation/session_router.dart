import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/result/result.dart';
import '../../family/domain/usecases/get_visible_matches.dart';
import '../../profile/domain/usecases/has_profile.dart';
import '../domain/entities/account_type.dart';
import '../domain/entities/auth_user.dart';

/// Where an already-active-session [user] should land — shared by
/// `InviteGateScreen` (cold-start restore, see `AuthCubit.restoreSession`)
/// and `OtpVerificationScreen` (mid-flow: the OTP just verified a phone
/// number that already belongs to a fully-onboarded account — Firebase
/// signs back into that SAME uid, so this "registration" attempt was
/// actually a login; see `AuthCubit.verifyOtp`'s `SessionActive` case).
/// Either way the answer is identical, so this lives in one place instead
/// of being duplicated per screen.
Future<void> routeActiveSession(BuildContext context, AuthUser user) async {
  if (user.verifiedAt == null) {
    // Signed in (OTP done) but never finished onboarding — resume right
    // where they left off rather than replaying invite/phone/OTP.
    context.go('/selfie-verification');
    return;
  }

  if (user.accountType == AccountType.guardian) {
    // FR-8 is on Firestore now, so link status genuinely survives a
    // reload — ask whether this guardian is actually linked yet (fails
    // with a "not linked" error otherwise) instead of always bouncing
    // back to the link screen.
    final result = await sl<GetVisibleMatches>()(user.id);
    if (!context.mounted) return;
    context.go(result is Ok ? '/guardian/home' : '/guardian/link');
    return;
  }

  final result = await sl<HasProfile>()(HasProfileParams(user.id));
  if (!context.mounted) return;
  switch (result) {
    case Ok<bool>(value: true):
      context.go('/discover');
    case Ok<bool>():
      context.go('/profile/photos');
    case Err<bool>():
      // Fail open to the profile wizard — re-submitting overwrites the
      // same document, so this is never destructive.
      context.go('/profile/photos');
  }
}
