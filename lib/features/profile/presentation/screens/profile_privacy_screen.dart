import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_cubit.dart';

/// FR-3.1/FR-3.2: the user picks how their photos reveal to others.
/// Reached right after photo selection — the draft already defaults to
/// the most restrictive level, so this screen is purely opt-in-to-expand.
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final selected = context.watch<ProfileCubit>().state.draft.photoVisibility;

    return Scaffold(
      appBar: AppBar(title: const Text('Mahremiyet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Fotoğraflarını kim, ne zaman görsün?', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Görünürlük bir varsayılan değil, bir tercih. Şu an en kısıtlı seviyedesin — '
                'istersen genişlet, istemezsen hiç dokunma.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 20),
              _VisibilityCard(
                title: 'Ben açana kadar gizli',
                subtitle: 'Kimseye otomatik ya da istek üzerine açılmaz. Varsayılan ve en kısıtlı seçenek.',
                level: PhotoVisibility.hiddenUntilIUnlock,
                selected: selected,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _VisibilityCard(
                title: 'Sadece istek üzerine',
                subtitle: 'Biri istediğinde bildirim alırsın, onaylarsan görünür.',
                level: PhotoVisibility.onRequestOnly,
                selected: selected,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _VisibilityCard(
                title: 'Eşleşince otomatik',
                subtitle: 'Karşılıklı eşleşme oluşunca otomatik açılır.',
                level: PhotoVisibility.autoOnMatch,
                selected: selected,
                colors: colors,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/profile/intent'),
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.selected,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final PhotoVisibility level;
  final PhotoVisibility selected;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = level == selected;

    return InkWell(
      onTap: () => context.read<ProfileCubit>().updatePhotoVisibility(level),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? colors.plumTint : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.plum : colors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colors.plum : colors.inkSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
