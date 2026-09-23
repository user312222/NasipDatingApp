import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/result/result.dart';
import '../../../../theme/app_colors.dart';
import '../../../profile/domain/usecases/has_profile.dart';
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
  Future<void> _routeAfterOnboarding(BuildContext context, AuthUser user) async {
    if (user.accountType == AccountType.single) {
      final result = await sl<HasProfile>()(HasProfileParams(user.id));
      if (!context.mounted) return;
      if (result case Ok<bool>(value: true)) {
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
      appBar: AppBar(title: const Text('Kimlik Doğrulama')),
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
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: colors.brass,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Son bir adım: canlılık doğrulaması.',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kimlik belgesi istemiyoruz — sadece kısa bir selfie ile bu hesabın gerçek, '
                      'canlı bir kişiye ait olduğunu doğruluyoruz. Fotoğrafın bizim sunucularımızda '
                      'hiçbir zaman saklanmaz; işlem tamamen bağımsız bir doğrulama sağlayıcısında yapılır.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => context
                                .read<AuthCubit>()
                                .submitSelfieVerification(_user),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Doğrulamayı başlat'),
                    ),
                    const SizedBox(height: 8),
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
