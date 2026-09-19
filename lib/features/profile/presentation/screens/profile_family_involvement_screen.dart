import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/profile_cubit.dart';

class ProfileFamilyInvolvementScreen extends StatefulWidget {
  const ProfileFamilyInvolvementScreen({super.key});

  @override
  State<ProfileFamilyInvolvementScreen> createState() =>
      _ProfileFamilyInvolvementScreenState();
}

class _ProfileFamilyInvolvementScreenState extends State<ProfileFamilyInvolvementScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Katılımı')),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSubmitted) context.go('/profile/complete');
          if (state is ProfileSubmitError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final optIn = state.draft.familyInvolvementOptIn;
            final isSubmitting = state is ProfileSubmitting;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Son bir tercih.', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Ailen/velin bu süreci görsün mü? Tamamen sana kalmış — istersen '
                      'süreci kendi başına, istersen ailenle birlikte yürüt. Sonradan da değiştirebilirsin.',
                      style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: SwitchListTile(
                        value: optIn,
                        onChanged: (v) => context.read<ProfileCubit>().updateFamilyInvolvement(v),
                        title: Text('Ailem/velim bu süreci görsün', style: textTheme.titleSmall),
                        activeThumbColor: colors.plum,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              final authState = context.read<AuthCubit>().state;
                              final userId = authState is OnboardingComplete
                                  ? authState.user.id
                                  : 'unknown_user';
                              context.read<ProfileCubit>().submit(userId);
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Profili tamamla'),
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
