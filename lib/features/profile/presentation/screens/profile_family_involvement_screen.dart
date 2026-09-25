import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/profile_cubit.dart';

class ProfileFamilyInvolvementScreen extends StatefulWidget {
  const ProfileFamilyInvolvementScreen({super.key});

  @override
  State<ProfileFamilyInvolvementScreen> createState() =>
      _ProfileFamilyInvolvementScreenState();
}

class _ProfileFamilyInvolvementScreenState
    extends State<ProfileFamilyInvolvementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSubmitted) context.go('/profile/complete');
          if (state is ProfileSubmitError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final optIn = state.draft.familyInvolvementOptIn;
            final isSubmitting = state is ProfileSubmitting;
            return WizardBackdrop(
              child: WizardBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WizardHeader(
                      icon: Icons.family_restroom_rounded,
                      title: 'Son bir tercih.',
                      subtitle:
                          'Ailen/velin bu süreci görsün mü? Tamamen sana kalmış — istersen '
                          'süreci kendi başına, istersen ailenle birlikte yürüt. Sonradan da değiştirebilirsin.',
                      step: 5,
                      totalSteps: 5,
                    ),
                    const SizedBox(height: 24),
                    OptionCard(
                      icon: Icons.family_restroom_outlined,
                      title: 'Ailem/velim bu süreci görsün',
                      subtitle: optIn
                          ? 'Açık — istediğin zaman kapatabilirsin.'
                          : 'Kapalı — süreci yalnızca sen görürsün.',
                      selected: optIn,
                      onTap: () => context
                          .read<ProfileCubit>()
                          .updateFamilyInvolvement(!optIn),
                    ),
                    const Spacer(),
                    GradientButton(
                      label: 'Profili tamamla',
                      loading: isSubmitting,
                      onPressed: () {
                        final userId =
                            context.read<AuthCubit>().currentUser?.id ??
                            'unknown_user';
                        context.read<ProfileCubit>().submit(userId);
                      },
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
