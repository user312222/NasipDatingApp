import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_cubit.dart';

String _visibilityLabel(PhotoVisibility v) => switch (v) {
  PhotoVisibility.hiddenUntilIUnlock => 'Fotoğrafların: ben açana kadar gizli',
  PhotoVisibility.onRequestOnly => 'Fotoğrafların: sadece istek üzerine',
  PhotoVisibility.autoOnMatch => 'Fotoğrafların: eşleşince otomatik',
};

class ProfileCompleteScreen extends StatelessWidget {
  const ProfileCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<ProfileCubit>().state;
    final profile = state is ProfileSubmitted ? state.profile : null;

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
                    icon: Icons.auto_awesome_rounded,
                    title: profile == null
                        ? 'Profilin hazır.'
                        : '${profile.name}, profilin hazır.',
                    subtitle: profile == null
                        ? null
                        : '${profile.city} · ${profile.age} · '
                              '${profile.intent.name == 'marriage' ? 'Evlilik' : 'Henüz emin değil'}'
                              '${profile.familyInvolvementOptIn ? ' · Aile dahil' : ''}',
                    centered: true,
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _visibilityLabel(profile.photoVisibility),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Keşfetmeye başla',
                    onPressed: () => context.go('/discover'),
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
