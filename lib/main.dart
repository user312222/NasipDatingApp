import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/restart/restart_app.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/family/presentation/bloc/guardian_cubit.dart';
import 'features/profile/presentation/bloc/profile_cubit.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  runApp(const RestartApp(child: BiNasipApp()));
}

class BiNasipApp extends StatelessWidget {
  const BiNasipApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthCubit and ProfileCubit are provided here, above the router, so
    // each flow's state (phone number / partially-verified user; the
    // profile draft) survives navigating between its own screens — see
    // core/router/app_router.dart.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<ProfileCubit>()),
        BlocProvider(create: (_) => sl<GuardianCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Bi Nasip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: appRouter,
      ),
    );
  }
}
