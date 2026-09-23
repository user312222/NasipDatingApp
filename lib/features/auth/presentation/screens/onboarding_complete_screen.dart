import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/account_type.dart';
import '../bloc/auth_cubit.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<AuthCubit>().state;
    final user = state is OnboardingComplete ? state.user : null;
    final isGuardian = user?.accountType == AccountType.guardian;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.verified_outlined, size: 48, color: colors.brass),
                const SizedBox(height: 16),
                Text(
                  isGuardian ? 'Hesabın hazır.' : 'Nasibin için hazırsın.',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user == null
                      ? 'Hesabın doğrulandı.'
                      : 'Hesabın (+90 ${user.phone}) doğrulandı.',
                  style: textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.push(
                    isGuardian ? '/guardian/link' : '/profile/photos',
                  ),
                  child: Text(
                    isGuardian ? 'Bağlantı kur' : 'Profilini oluştur',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
