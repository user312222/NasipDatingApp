import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_invite_code.dart';
import '../../features/auth/domain/usecases/request_phone_otp.dart';
import '../../features/auth/domain/usecases/submit_selfie_verification.dart';
import '../../features/auth/domain/usecases/verify_phone_otp.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/matching/data/datasources/matching_remote_data_source.dart';
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/matching/domain/repositories/matching_repository.dart';
import '../../features/matching/domain/usecases/get_candidates.dart';
import '../../features/matching/domain/usecases/swipe_candidate.dart';
import '../../features/matching/presentation/bloc/matching_cubit.dart';
import '../../features/messaging/data/datasources/messaging_remote_data_source.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/domain/usecases/dismiss_family_nudge.dart';
import '../../features/messaging/domain/usecases/open_conversation.dart';
import '../../features/messaging/domain/usecases/send_message.dart';
import '../../features/messaging/presentation/bloc/chat_cubit.dart';
import '../../features/profile/data/datasources/profile_local_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/save_profile.dart';
import '../../features/profile/presentation/bloc/profile_cubit.dart';
import '../../features/waitlist/data/datasources/waitlist_local_data_source.dart';
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
  _initWaitlist();
  _initAuth();
  _initProfile();
  _initMatching();
  _initMessaging();
}

void _initWaitlist() {
  // Presentation
  sl.registerFactory(() => WaitlistCubit(submitWaitlistEntry: sl()));

  // Domain
  sl.registerLazySingleton(() => SubmitWaitlistEntry(sl()));

  // Data
  sl.registerLazySingleton<WaitlistRepository>(
    () => WaitlistRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<WaitlistLocalDataSource>(
    () => WaitlistLocalDataSourceImpl(),
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
    ),
  );

  // Domain
  sl.registerLazySingleton(() => CheckInviteCode(sl()));
  sl.registerLazySingleton(() => RequestPhoneOtp(sl()));
  sl.registerLazySingleton(() => VerifyPhoneOtp(sl()));
  sl.registerLazySingleton(() => SubmitSelfieVerification(sl()));

  // Data
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(() => MockAuthRemoteDataSource());
}

void _initProfile() {
  // Presentation — provided at the app root, same reasoning as AuthCubit.
  sl.registerFactory(() => ProfileCubit(saveProfile: sl()));

  // Domain
  sl.registerLazySingleton(() => SaveProfile(sl()));

  // Data
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(() => ProfileLocalDataSourceImpl());
}

void _initMatching() {
  // Presentation — provided at the app root, same reasoning as the others.
  sl.registerFactory(
    () => MatchingCubit(getCandidates: sl(), swipeCandidate: sl()),
  );

  // Domain
  sl.registerLazySingleton(() => GetCandidates(sl()));
  sl.registerLazySingleton(() => SwipeCandidate(sl()));

  // Data
  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MatchingRemoteDataSource>(() => MockMatchingRemoteDataSource());
}

void _initMessaging() {
  // Presentation — provided locally by ChatScreen, same reasoning as
  // MatchingCubit/DiscoveryScreen.
  sl.registerFactory(
    () => ChatCubit(
      openConversation: sl(),
      sendMessage: sl(),
      dismissFamilyNudge: sl(),
    ),
  );

  // Domain
  sl.registerLazySingleton(() => OpenConversation(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => DismissFamilyNudge(sl()));

  // Data
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MessagingRemoteDataSource>(() => MockMessagingRemoteDataSource());
}
