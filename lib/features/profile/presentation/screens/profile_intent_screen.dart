import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_cubit.dart';

class ProfileIntentScreen extends StatelessWidget {
  const ProfileIntentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final selected = context.watch<ProfileCubit>().state.draft.intent;

    return Scaffold(
      appBar: AppBar(title: const Text('Niyetin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bi Nasip’te ne arıyorsun?', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Bu, profilinde görünür ve eşleşmelerinin de niyetini bilmesini sağlar.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 24),
              _IntentCard(
                title: 'Evlilik',
                subtitle: 'Ciddi, evliliğe yönelik bir ilişki arıyorum.',
                selected: selected == ProfileIntent.marriage,
                onTap: () => context.read<ProfileCubit>().updateIntent(
                  ProfileIntent.marriage,
                ),
              ),
              const SizedBox(height: 12),
              _IntentCard(
                title: 'Henüz emin değilim',
                subtitle: 'Süreç içinde netleşsin istiyorum.',
                selected: selected == ProfileIntent.notSureYet,
                onTap: () => context.read<ProfileCubit>().updateIntent(
                  ProfileIntent.notSureYet,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () => context.push('/profile/details'),
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? colors.plumTint : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.plum : colors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? colors.plum : colors.inkSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
