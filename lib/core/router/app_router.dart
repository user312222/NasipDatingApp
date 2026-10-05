import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/presentation/screens/account_type_screen.dart';
import '../../features/auth/presentation/screens/invite_gate_screen.dart';
import '../../features/consent/presentation/screens/consent_screen.dart';
import '../../features/family/presentation/screens/family_link_screen.dart';
import '../../features/family/presentation/screens/guardian_home_screen.dart';
import '../../features/family/presentation/screens/guardian_link_screen.dart';
import '../../features/auth/presentation/screens/onboarding_complete_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/phone_entry_screen.dart';
import '../../features/auth/presentation/screens/selfie_verification_screen.dart';
import '../../features/feed/presentation/bloc/feed_badge_cubit.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/matching/presentation/bloc/matches_cubit.dart';
import '../../features/matching/presentation/screens/discovery_screen.dart';
import '../../features/matching/presentation/screens/matches_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_complete_screen.dart';
import '../../features/profile/presentation/screens/profile_details_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_family_involvement_screen.dart';
import '../../features/profile/presentation/screens/profile_intent_screen.dart';
import '../../features/profile/presentation/screens/profile_photos_screen.dart';
import '../../features/profile/presentation/screens/profile_privacy_screen.dart';
import '../../features/waitlist/presentation/screens/waitlist_screen.dart';
import '../../screens/design_preview_screen.dart';
import '../di/injection_container.dart';
import 'main_shell.dart';
import 'profile_status_cache.dart';
import 'route_access.dart';

const _feedTab = 1;
const _matchesTab = 2;

bool _hasUnread(MatchesState state) =>
    state is MatchesLoaded && state.hasUnread;

/// Runs before every navigation and applies the rules in
/// `route_access.dart`: who may open which location. It also covers the
/// cold start - session restore only runs from `/` (`InviteGateScreen`
/// calls `AuthCubit.restoreSession`), and a web reload or deep link that
/// starts elsewhere finds nobody signed in yet, so it is sent through `/`
/// and routed onward from there.
///
/// Synchronous whenever the answer is already known; only the first visit
/// of a single user to the app proper waits for one profile lookup.
FutureOr<String?> _guard(BuildContext context, GoRouterState state) {
  final auth = context.read<AuthCubit>();
  final location = state.matchedLocation;
  final user = auth.currentUser;

  String? decide(bool? hasProfile) => accessRedirect(
    location,
    AccessContext(
      user: user,
      hasProfile: hasProfile,
      inviteAccepted: auth.inviteAccepted,
      consentAccepted: auth.consentAccepted,
      signingIn: auth.isSigningIn,
      otpRequested: auth.otpRequested,
      hasChatArgs: state.extra is ChatRouteArgs,
    ),
  );

  if (user == null || !needsProfileCheck(location, user)) return decide(null);
  final profiles = sl<ProfileStatusCache>();
  if (profiles.isKnown(user.id)) return decide(true);
  return profiles.check(user.id).then(decide);
}

/// App-wide route table. Each feature contributes its screens here;
/// once a feature grows routes of its own it can expose a
/// `List<RouteBase> waitlistRoutes` and this file just concatenates them.
///
/// FR-1 onboarding flow: `/` → `/phone` → `/otp` → `/selfie-verification`
/// → `/onboarding-complete`. All of it reads one shared `AuthCubit`
/// provided above the router in `main.dart`, so state (phone number,
/// partially-verified user) survives navigating between steps.
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: _guard,
  // Unknown addresses (a mistyped link, or the debug-only gallery in a
  // release build) fall back to the entry screen, which restores the
  // session, instead of go_router's bare "Page Not Found".
  onException: (context, state, router) => router.go('/'),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const InviteGateScreen()),
    GoRoute(
      path: '/waitlist',
      builder: (context, state) => const WaitlistScreen(),
    ),
    GoRoute(
      path: '/account-type',
      builder: (context, state) => const AccountTypeScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/guardian/link',
      builder: (context, state) => const GuardianLinkScreen(),
    ),
    GoRoute(
      path: '/guardian/home',
      builder: (context, state) => const GuardianHomeScreen(),
    ),
    GoRoute(
      path: '/family/settings',
      builder: (context, state) => const FamilyLinkScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/phone',
      builder: (context, state) => const PhoneEntryScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/selfie-verification',
      builder: (context, state) => const SelfieVerificationScreen(),
    ),
    GoRoute(
      path: '/onboarding-complete',
      builder: (context, state) => const OnboardingCompleteScreen(),
    ),
    GoRoute(
      path: '/profile/photos',
      builder: (context, state) => const ProfilePhotosScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) => const ProfilePrivacyScreen(),
    ),
    GoRoute(
      path: '/profile/intent',
      builder: (context, state) => const ProfileIntentScreen(),
    ),
    GoRoute(
      path: '/profile/details',
      builder: (context, state) => const ProfileDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/family',
      builder: (context, state) => const ProfileFamilyInvolvementScreen(),
    ),
    GoRoute(
      path: '/profile/complete',
      builder: (context, state) => const ProfileCompleteScreen(),
    ),
    // Opened from the Hesap tab; covers the tab bar like the chat does.
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => ProfileEditScreen(
        // `_guard` only lets a signed-in single with a profile through.
        userId: context.read<AuthCubit>().currentUser?.id ?? 'unknown_user',
      ),
    ),
    // The single user's home: four tabs behind the bottom bar. `/account`
    // is the same screen as `/settings`, which stays a standalone route for
    // guardian accounts (they have no tabs).
    StatefulShellRoute.indexedStack(
      // One MatchesCubit for the whole tab bar: it feeds both the
      // Eşleşmeler tab and the unread dot on that tab, so the dot is live
      // even while another tab is open. FeedBadgeCubit does the same for
      // the "not answered yet" dot on the Günün Sorusu tab.
      builder: (context, state, navigationShell) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<MatchesCubit>()..load()),
          BlocProvider(create: (_) => sl<FeedBadgeCubit>()..start()),
        ],
        child: BlocBuilder<MatchesCubit, MatchesState>(
          buildWhen: (previous, current) =>
              _hasUnread(previous) != _hasUnread(current),
          builder: (context, matches) => BlocBuilder<FeedBadgeCubit, bool>(
            builder: (context, questionWaiting) => MainShell(
              navigationShell: navigationShell,
              badges: {
                if (questionWaiting) _feedTab: 'bugünün sorusu seni bekliyor',
                if (_hasUnread(matches)) _matchesTab: 'yeni mesaj var',
              },
              onTabSelected: (index) {
                if (index == _matchesTab) {
                  context.read<MatchesCubit>().refresh();
                }
              },
            ),
          ),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const DiscoveryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/matches',
              builder: (context, state) =>
                  const MatchesScreen(ownsCubit: false),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        // `_guard` only lets this location through with its arguments.
        final args = state.extra! as ChatRouteArgs;
        return ChatScreen(
          matchId: args.matchId,
          otherPartyUserId: args.otherPartyUserId,
          otherPartyName: args.otherPartyName,
          otherPartyAvatarSeed: args.otherPartyAvatarSeed,
        );
      },
    ),
    // Developer gallery - debug builds only, so it never ships to users.
    if (kDebugMode)
      GoRoute(
        path: '/design-preview',
        builder: (context, state) => const DesignPreviewScreen(),
      ),
  ],
);
