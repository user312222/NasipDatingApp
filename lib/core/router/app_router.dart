import 'package:go_router/go_router.dart';

import '../../features/account/presentation/screens/settings_screen.dart';
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
import '../../features/matching/presentation/screens/discovery_screen.dart';
import '../../features/matching/presentation/screens/matches_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_complete_screen.dart';
import '../../features/profile/presentation/screens/profile_details_screen.dart';
import '../../features/profile/presentation/screens/profile_family_involvement_screen.dart';
import '../../features/profile/presentation/screens/profile_intent_screen.dart';
import '../../features/profile/presentation/screens/profile_photos_screen.dart';
import '../../features/profile/presentation/screens/profile_privacy_screen.dart';
import '../../features/waitlist/presentation/screens/waitlist_screen.dart';
import '../../screens/design_preview_screen.dart';

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
    GoRoute(
      path: '/discover',
      builder: (context, state) => const DiscoveryScreen(),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => const MatchesScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final args = state.extra! as ChatRouteArgs;
        return ChatScreen(
          matchId: args.matchId,
          otherPartyUserId: args.otherPartyUserId,
          otherPartyName: args.otherPartyName,
          otherPartyAvatarSeed: args.otherPartyAvatarSeed,
        );
      },
    ),
    GoRoute(
      path: '/design-preview',
      builder: (context, state) => const DesignPreviewScreen(),
    ),
  ],
);
