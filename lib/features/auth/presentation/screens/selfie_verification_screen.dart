import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/profile_status_cache.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';
import '../bloc/auth_cubit.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  late final AuthUser _user;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    _user = state is PhoneVerified
        ? state.user
        : const AuthUser(id: '', phone: '');
  }

  /// The `users/{uid}.verifiedAt`-based shortcut in `AuthCubit.verifyOtp`
  /// only fires for accounts that finished selfie verification *after*
  /// that persistence was added — every older account still lands here
  /// every time. `profiles/{uid}` existence is a much older, reliable
  /// signal (unchanged since the FR-2 Firestore migration), so this is
  /// the check that actually protects every already-onboarded account
  /// from being sent through the profile wizard — and re-uploading
  /// photos — a second time.
  Future<void> _routeAfterOnboarding(
    BuildContext context,
    AuthUser user,
  ) async {
    if (user.accountType == AccountType.single) {
      final hasProfile = await sl<ProfileStatusCache>().check(user.id);
      if (!context.mounted) return;
      if (hasProfile == true) {
        context.go('/discover');
        return;
      }
    }
    if (!context.mounted) return;
    context.go('/onboarding-complete');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is OnboardingComplete) {
            _routeAfterOnboarding(context, state.user);
          }
          if (state is SelfieVerificationFailed) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isSubmitting = state is SelfieVerificationInProgress;
            return WizardBackdrop(
              child: WizardBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WizardHeader(
                      icon: Icons.camera_alt_rounded,
                      title: 'Son bir adım: canlılık doğrulaması.',
                      subtitle:
                          'Kimlik belgesi istemiyoruz — sadece kısa bir selfie ile bu hesabın gerçek, '
                          'canlı bir kişiye ait olduğunu doğruluyoruz. Fotoğrafın bizim sunucularımızda '
                          'hiçbir zaman saklanmaz; işlem tamamen bağımsız bir doğrulama sağlayıcısında yapılır.',
                      step: 5,
                      totalSteps: 5,
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Doğrulamayı başlat',
                      loading: isSubmitting,
                      onPressed: () => context
                          .read<AuthCubit>()
                          .submitSelfieVerification(_user),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '(Bu ön izlemede gerçek kamera açılmaz — sağlayıcı entegrasyonu bağlanınca eklenecek.)',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
