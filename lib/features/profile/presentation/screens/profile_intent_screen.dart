import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_cubit.dart';

class ProfileIntentScreen extends StatelessWidget {
  const ProfileIntentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ProfileCubit>().state.draft.intent;

    return Scaffold(
      appBar: AppBar(),
      body: WizardBackdrop(
        child: WizardBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WizardHeader(
                icon: Icons.favorite_rounded,
                title: 'Bi Nasip’te ne arıyorsun?',
                subtitle: 'Bu, profilinde görünür ve eşleşmelerinin de niyetini bilmesini sağlar.',
                step: 3,
                totalSteps: 5,
              ),
              const SizedBox(height: 26),
              OptionCard(
                icon: Icons.diamond_outlined,
                title: 'Evlilik',
                subtitle: 'Ciddi, evliliğe yönelik bir ilişki arıyorum.',
                selected: selected == ProfileIntent.marriage,
                onTap: () => context.read<ProfileCubit>().updateIntent(
                  ProfileIntent.marriage,
                ),
              ),
              const SizedBox(height: 12),
              OptionCard(
                icon: Icons.hourglass_empty_rounded,
                title: 'Henüz emin değilim',
                subtitle: 'Süreç içinde netleşsin istiyorum.',
                selected: selected == ProfileIntent.notSureYet,
                onTap: () => context.read<ProfileCubit>().updateIntent(
                  ProfileIntent.notSureYet,
                ),
              ),
              const Spacer(),
              GradientButton(
                label: 'Devam et',
                onPressed: selected == null
                    ? null
                    : () => context.push('/profile/details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
