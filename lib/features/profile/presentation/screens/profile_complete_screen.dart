import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.auto_awesome, size: 48, color: colors.brass),
                const SizedBox(height: 16),
                Text(
                  profile == null ? 'Profilin hazır.' : '${profile.name}, profilin hazır.',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  profile == null
                      ? ''
                      : '${profile.city} · ${profile.age} · '
                            '${profile.intent.name == 'marriage' ? 'Evlilik' : 'Henüz emin değil'}'
                            '${profile.familyInvolvementOptIn ? ' · Aile dahil' : ''}',
                  style: textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
                  textAlign: TextAlign.center,
                ),
                if (profile != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _visibilityLabel(profile.photoVisibility),
                    style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/discover'),
                  child: const Text('Keşfetmeye başla'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
