import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences/app_preferences.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_invite_code.dart';
import '../../features/auth/domain/usecases/get_current_session.dart';
import '../../features/auth/domain/usecases/log_out.dart';
import '../../features/auth/domain/usecases/request_phone_otp.dart';
import '../../features/auth/domain/usecases/submit_selfie_verification.dart';
import '../../features/auth/domain/usecases/verify_phone_otp.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/account/data/datasources/account_remote_data_source.dart';
import '../../features/account/data/datasources/firestore_account_remote_data_source.dart';
import '../../features/consent/data/datasources/consent_remote_data_source.dart';
import '../../features/consent/data/datasources/firestore_consent_remote_data_source.dart';
import '../../features/consent/data/repositories/consent_repository_impl.dart';
import '../../features/consent/domain/repositories/consent_repository.dart';
import '../../features/consent/domain/usecases/record_consent.dart';
import '../../features/account/data/repositories/account_repository_impl.dart';
import '../../features/account/domain/repositories/account_repository.dart';
import '../../features/account/domain/usecases/delete_account.dart';
import '../../features/account/presentation/bloc/account_cubit.dart';
import '../../features/family/data/datasources/family_remote_data_source.dart';
import '../../features/family/data/datasources/firestore_family_remote_data_source.dart';
import '../../features/family/data/repositories/family_repository_impl.dart';
import '../../features/family/domain/repositories/family_repository.dart';
import '../../features/family/domain/usecases/get_or_create_invite_code.dart';
import '../../features/family/domain/usecases/get_visible_matches.dart';
import '../../features/family/domain/usecases/link_guardian.dart';
import '../../features/family/presentation/bloc/family_link_cubit.dart';
import '../../features/family/presentation/bloc/guardian_cubit.dart';
import '../../features/matching/data/datasources/firestore_matching_remote_data_source.dart';
import '../../features/matching/data/datasources/matching_remote_data_source.dart';
import '../../features/matching/domain/usecases/get_my_matches.dart';
import '../../features/matching/domain/usecases/set_match_visible_to_family.dart';
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/matching/domain/repositories/matching_repository.dart';
import '../../features/matching/domain/usecases/get_candidates.dart';
import '../../features/matching/domain/usecases/swipe_candidate.dart';
import '../../features/matching/presentation/bloc/matches_cubit.dart';
import '../../features/matching/presentation/bloc/matching_cubit.dart';
import '../../features/messaging/data/datasources/firestore_messaging_remote_data_source.dart';
import '../../features/messaging/data/datasources/messaging_remote_data_source.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/dismiss_family_nudge.dart';
import '../../features/messaging/domain/usecases/mark_conversation_read.dart';
import '../../features/messaging/domain/usecases/send_message.dart';
import '../../features/messaging/domain/usecases/watch_conversation.dart';
import '../../features/messaging/domain/usecases/watch_last_messages.dart';
import '../../features/messaging/domain/usecases/watch_read_times.dart';
import '../../features/messaging/presentation/bloc/chat_cubit.dart';
import '../../features/safety/data/datasources/firestore_safety_remote_data_source.dart';
import '../../features/safety/data/datasources/safety_remote_data_source.dart';
import '../../features/safety/data/repositories/safety_repository_impl.dart';
import '../../features/safety/domain/repositories/safety_repository.dart';
import '../../features/safety/domain/usecases/block_user.dart';
import '../../features/safety/domain/usecases/moderate_photo.dart';
import '../../features/safety/domain/usecases/report_user.dart';
import '../../features/safety/presentation/bloc/safety_cubit.dart';
import '../../features/profile/data/datasources/firestore_profile_remote_data_source.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/has_profile.dart';
import '../../features/profile/domain/usecases/save_profile.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';
import '../../features/waitlist/data/datasources/waitlist_remote_data_source.dart';
import '../../features/waitlist/data/repositories/waitlist_repository_impl.dart';
import '../../features/waitlist/domain/repositories/waitlist_repository.dart';
import '../../features/waitlist/domain/usecases/submit_waitlist_entry.dart';
import '../../features/waitlist/presentation/bloc/waitlist_cubit.dart';

/// Service locator. Call [initDependencies] once, in `main()`, before
/// `runApp`. Each feature registers its own dependencies in a
/// `_initWaitlist()`-style private function to keep this file readable as
/// more features land.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  final appPreferences = AppPreferences(await SharedPreferences.getInstance());
  await appPreferences.init();
  sl.registerSingleton<AppPreferences>(appPreferences);

  _initWaitlist();
  _initConsent();
  _initAuth();
  _initProfile();
  _initMatching();
  _initMessaging();
  _initFamily();
  _initSafety();
  _initAccount();
}

void _initWaitlist() {
  // Presentation
  sl.registerFactory(() => WaitlistCubit(submitWaitlistEntry: sl()));

  // Domain
  sl.registerLazySingleton(() => SubmitWaitlistEntry(sl()));

  // Data
  sl.registerLazySingleton<WaitlistRepository>(
    () => WaitlistRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<WaitlistRemoteDataSource>(
    () => FirestoreWaitlistRemoteDataSource(),
  );
}

void _initAuth() {
  // Presentation — registered once and provided at the app root (see
  // main.dart) so the flow's state survives navigating between screens.
  sl.registerFactory(
    () => AuthCubit(
      checkInviteCode: sl(),
      requestPhoneOtp: sl(),
      verifyPhoneOtp: sl(),
      submitSelfieVerification: sl(),
      getCurrentSession: sl(),
      recordConsent: sl(),
    ),
  );

  // Domain
  sl.registerLazySingleton(() => CheckInviteCode(sl()));
  sl.registerLazySingleton(() => RequestPhoneOtp(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtp(sl()));
  sl.registerLazySingleton(() => SubmitSelfieVerification(sl()));
  sl.registerLazySingleton(() => GetCurrentSession(sl()));
  sl.registerLazySingleton(() => LogOut(sl()));

  // Data
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSource(fallback: MockAuthRemoteDataSource()),
  );
}

void _initConsent() {
  // Domain
  sl.registerLazySingleton(() => RecordConsent(sl()));

  // Data
  sl.registerLazySingleton<ConsentRepository>(
    () => ConsentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ConsentRemoteDataSource>(
    () => FirestoreConsentRemoteDataSource(),
  );
}

void _initProfile() {
  // Presentation — provided at the app root, same reasoning as AuthCubit.
  sl.registerFactory(() => ProfileCubit(saveProfile: sl()));

  // Domain
  sl.registerLazySingleton(() => SaveProfile(sl()));
  sl.registerLazySingleton(() => HasProfile(sl()));

  // Data
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => FirestoreProfileRemoteDataSource(),
  );
}

void _initMatching() {
  // Presentation — provided at the app root, same reasoning as the others.
  sl.registerFactory(
    () => MatchingCubit(getCandidates: sl(), swipeCandidate: sl()),
  );
  sl.registerFactory(
    () => MatchesCubit(
      getMyMatches: sl(),
      watchLastMessages: sl(),
      watchReadTimes: sl(),
    ),
  );

  // Domain
  sl.registerLazySingleton(() => GetCandidates(sl()));
  sl.registerLazySingleton(() => SwipeCandidate(sl()));
  sl.registerLazySingleton(() => GetMyMatches(sl()));
  sl.registerLazySingleton(() => SetMatchVisibleToFamily(sl()));

  // Data
  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MatchingRemoteDataSource>(
    () => FirestoreMatchingRemoteDataSource(sl()),
  );
}

void _initMessaging() {
  // Presentation — provided locally by ChatScreen, same reasoning as
  // MatchingCubit/DiscoveryScreen.
  sl.registerFactory(
    () => ChatCubit(
      watchConversation: sl(),
      sendMessage: sl(),
      dismissFamilyNudge: sl(),
      markConversationRead: sl(),
    ),
  );

  // Domain
  sl.registerLazySingleton(() => WatchConversation(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => DismissFamilyNudge(sl()));
  sl.registerLazySingleton(() => WatchLastMessages(sl()));
  sl.registerLazySingleton(() => WatchReadTimes(sl()));
  sl.registerLazySingleton(() => MarkConversationRead(sl()));

  // Data
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => FirestoreMessagingRemoteDataSource(),
  );
}

void _initAccount() {
  // Presentation — provided locally by SettingsScreen.
  sl.registerFactory(() => AccountCubit(deleteAccount: sl(), logOut: sl()));

  // Domain
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  // Data
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => FirestoreAccountRemoteDataSource(),
  );
}

void _initSafety() {
  // Presentation — each SafetyMenuButton provides its own cubit.
  sl.registerFactory(() => SafetyCubit(reportUser: sl(), blockUser: sl()));

  // Domain
  sl.registerLazySingleton(() => ReportUser(sl()));
  sl.registerLazySingleton(() => BlockUser(sl()));
  sl.registerLazySingleton(() => ModeratePhoto(sl()));

  // Data
  sl.registerLazySingleton<SafetyRepository>(
    () => SafetyRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SafetyRemoteDataSource>(
    () => FirestoreSafetyRemoteDataSource(),
  );
}

void _initFamily() {
  // Presentation — GuardianCubit at the app root (two screens share it);
  // FamilyLinkCubit is provided locally by FamilyLinkScreen.
  sl.registerFactory(
    () => GuardianCubit(linkGuardian: sl(), getVisibleMatches: sl()),
  );
  sl.registerFactory(
    () => FamilyLinkCubit(
      getOrCreateInviteCode: sl(),
      getMyMatches: sl(),
      setMatchVisibleToFamily: sl(),
    ),
  );

  // Domain
  sl.registerLazySingleton(() => LinkGuardian(sl()));
  sl.registerLazySingleton(() => GetVisibleMatches(sl()));
  sl.registerLazySingleton(() => GetOrCreateInviteCode(sl()));

  // Data — the mock family source shares the mock matching source's
  // in-memory store (a real backend would just query the same collection).
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<FamilyRemoteDataSource>(
    () => FirestoreFamilyRemoteDataSource(),
  );
}
