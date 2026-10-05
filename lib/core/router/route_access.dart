import 'package:flutter/foundation.dart';

import '../../features/auth/domain/entities/account_type.dart';
import '../../features/auth/domain/entities/auth_user.dart';

/// Everything the router needs to know to decide whether a location may be
/// opened right now. Built fresh for each navigation from `AuthCubit` (and
/// the profile cache) by `app_router.dart`; kept as plain data so the rules
/// below can be tested without a widget tree.
@immutable
class AccessContext {
  const AccessContext({
    this.user,
    this.hasProfile,
    this.inviteAccepted = false,
    this.consentAccepted = false,
    this.signingIn = false,
    this.otpRequested = false,
    this.hasChatArgs = false,
  });

  /// The signed-in account, or null when nobody is signed in.
  final AuthUser? user;

  /// Whether the signed-in single has a profile. Null means "not known"
  /// (the check failed, or was not needed) and never blocks anyone.
  final bool? hasProfile;

  /// Registration door: an invite code was accepted in this session.
  final bool inviteAccepted;

  /// Registration door: the KVKK notices were accepted in this session.
  final bool consentAccepted;

  /// The "Hesabım var" door was taken.
  final bool signingIn;

  /// A verification code was requested, so there is a number to verify.
  final bool otpRequested;

  /// `/chat` was opened with the conversation it should show.
  final bool hasChatArgs;
}

/// Pages anyone may open, signed in or not.
const publicRoutes = {'/', '/waitlist', if (kDebugMode) '/design-preview'};

/// The single user's app proper: needs a finished profile.
const _singleAppRoutes = {
  '/discover',
  '/feed',
  '/matches',
  '/account',
  '/chat',
  '/family/settings',
  '/profile/edit',
};

/// The steps of the profile wizard: for creating a profile, not for
/// changing one (that is `/profile/edit`).
const _wizardSteps = {
  '/profile/photos',
  '/profile/privacy',
  '/profile/intent',
  '/profile/details',
  '/profile/family',
};

bool isWizardStep(String location) => _wizardSteps.contains(location);

/// Whether [location] is one where a single user's profile matters, i.e.
/// the router should look the profile up before deciding.
bool needsProfileCheck(String location, AuthUser? user) =>
    user != null &&
    user.isVerified &&
    user.accountType == AccountType.single &&
    (_singleAppRoutes.contains(location) || location.startsWith('/profile/'));

/// Where [location] should be redirected to, or null when it may be shown.
///
/// On the web every location can be typed into the address bar, so the
/// order of the onboarding steps (invite code -> account type -> consent ->
/// phone -> code -> liveness -> profile) and the split between single and
/// guardian accounts cannot rest on which buttons exist. Each rule below
/// answers "what must already be true to be here?" and otherwise sends the
/// person to the step they actually belong on.
String? accessRedirect(String location, AccessContext access) {
  if (publicRoutes.contains(location)) return null;

  // --- Before sign-in: the two doors -----------------------------------
  switch (location) {
    case '/account-type' || '/consent':
      return access.inviteAccepted ? null : '/';
    case '/phone':
      // Sign-in needs nothing first; registration needs the invite code
      // and the consent, in that order (FR-1.3, FR-1.4).
      return access.signingIn ||
              (access.inviteAccepted && access.consentAccepted)
          ? null
          : '/';
    case '/otp':
      return access.otpRequested ? null : '/';
  }

  // --- Everything else needs a session ---------------------------------
  final user = access.user;
  if (user == null) return '/';

  // FR-1.2: nothing past the liveness step until it is done.
  if (!user.isVerified) {
    return location == '/selfie-verification' ? null : '/selfie-verification';
  }

  final guardian = user.accountType == AccountType.guardian;
  final home = guardian
      ? '/guardian/home'
      : (access.hasProfile == false ? '/profile/photos' : '/discover');

  if (location == '/selfie-verification') return home;
  if (location == '/onboarding-complete' || location == '/settings') {
    return null;
  }

  // FR-8.6: a guardian account reaches the guardian screens and nothing of
  // the single user's app.
  if (guardian) {
    return location.startsWith('/guardian/') ? null : home;
  }
  if (location.startsWith('/guardian/')) return home;

  // --- Single accounts --------------------------------------------------
  // Checked before the wizard: `/profile/edit` is part of the app proper.
  if (_singleAppRoutes.contains(location)) {
    if (access.hasProfile == false) return '/profile/photos';
    // A chat page with no conversation to show (typed address, reload).
    if (location == '/chat' && !access.hasChatArgs) return '/matches';
    return null;
  }

  // The wizard creates a profile, once. With a profile its steps lead to
  // the edit screen instead - going through them again would rewrite the
  // whole profile, birth date included, which is fixed after registration
  // (FR-2.5).
  if (isWizardStep(location)) {
    return access.hasProfile == true ? '/profile/edit' : null;
  }

  // Its last page shows the finished profile, so only once there is one.
  if (location == '/profile/complete' && access.hasProfile == false) {
    return '/profile/photos';
  }

  return null;
}
