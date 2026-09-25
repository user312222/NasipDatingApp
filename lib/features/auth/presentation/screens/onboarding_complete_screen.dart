import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/account_type.dart';
import '../bloc/auth_cubit.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final user = state is OnboardingComplete ? state.user : null;
    final isGuardian = user?.accountType == AccountType.guardian;

    return Scaffold(
      body: WizardBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WizardHeader(
                    icon: Icons.verified_rounded,
                    title: isGuardian
                        ? 'Hesabın hazır.'
                        : 'Nasibin için hazırsın.',
                    subtitle: user == null
                        ? 'Hesabın doğrulandı.'
                        : 'Hesabın (+90 ${user.phone}) doğrulandı.',
                    centered: true,
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: isGuardian ? 'Bağlantı kur' : 'Profilini oluştur',
                    onPressed: () => context.push(
                      isGuardian ? '/guardian/link' : '/profile/photos',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
