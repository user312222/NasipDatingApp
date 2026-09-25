import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_cubit.dart';

/// FR-3.1/FR-3.2: the user picks how their photos reveal to others.
/// Reached right after photo selection — the draft already defaults to
/// the most restrictive level, so this screen is purely opt-in-to-expand.
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ProfileCubit>().state.draft.photoVisibility;

    void select(PhotoVisibility level) =>
        context.read<ProfileCubit>().updatePhotoVisibility(level);

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
              OptionCard(
                icon: Icons.visibility_off_outlined,
                title: 'Ben açana kadar gizli',
                subtitle: 'Kimseye otomatik ya da istek üzerine açılmaz. Varsayılan ve en kısıtlı seçenek.',
                selected: selected == PhotoVisibility.hiddenUntilIUnlock,
                onTap: () => select(PhotoVisibility.hiddenUntilIUnlock),
              ),
              const SizedBox(height: 12),
              OptionCard(
                icon: Icons.mark_email_unread_outlined,
                title: 'Sadece istek üzerine',
                subtitle:
                    'Biri istediğinde bildirim alırsın, onaylarsan görünür.',
                selected: selected == PhotoVisibility.onRequestOnly,
                onTap: () => select(PhotoVisibility.onRequestOnly),
              ),
              const SizedBox(height: 12),
              OptionCard(
                icon: Icons.favorite_border_rounded,
                title: 'Eşleşince otomatik',
                subtitle: 'Karşılıklı eşleşme oluşunca otomatik açılır.',
                selected: selected == PhotoVisibility.autoOnMatch,
                onTap: () => select(PhotoVisibility.autoOnMatch),
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
