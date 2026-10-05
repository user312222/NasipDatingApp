import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../bloc/profile_cubit.dart';
import '../widgets/profile_form_parts.dart';

/// FR-3.1/FR-3.2: the user picks how their photos reveal to others.
/// Reached right after photo selection — the draft already defaults to
/// the most restrictive level, so this screen is purely opt-in-to-expand.
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ProfileCubit>().state.draft.photoVisibility;

    return Scaffold(
      appBar: AppBar(),
      body: WizardBackdrop(
        child: WizardBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WizardHeader(
                icon: Icons.lock_rounded,
                title: 'Fotoğraflarını kim, ne zaman görsün?',
                subtitle:
                    'Görünürlük bir varsayılan değil, bir tercih. Şu an en kısıtlı seviyedesin — '
                    'istersen genişlet, istemezsen hiç dokunma.',
                step: 2,
                totalSteps: 5,
              ),
              const SizedBox(height: 22),
              PhotoVisibilityOptions(
                selected: selected,
                onChanged: context.read<ProfileCubit>().updatePhotoVisibility,
              ),
              const Spacer(),
              GradientButton(
                label: 'Devam et',
                onPressed: () => context.push('/profile/intent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
