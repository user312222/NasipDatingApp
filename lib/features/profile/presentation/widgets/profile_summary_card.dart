import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_summary_cubit.dart';

/// The "Profilin" card on the Hesap tab: who the member is to others -
/// name, age, city - and the way into "Profili düzenle". Until the profile
/// is read (or when it cannot be) it shows what the button is for instead.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.userId,
    this.enabled = true,
  });

  final String userId;

  /// False while the account is being signed out or deleted.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileSummaryCubit>()..load(userId),
      child: BlocBuilder<ProfileSummaryCubit, Profile?>(
        builder: (context, profile) => SectionCard(
          icon: Icons.badge_outlined,
          title: 'Profilin',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: profile == null
                    ? Text(
                        'Adını, şehrini, niyetini, hakkındaki bilgileri ve '
                        'fotoğraf görünürlüğünü buradan güncelleyebilirsin.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.colors.inkSoft),
                      )
                    : _Summary(profile: profile),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: enabled ? () => _edit(context) : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Profili düzenle'),
                style: sectionActionStyle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final summary = context.read<ProfileSummaryCubit>();
    await context.push('/profile/edit');
    // Whatever was saved there should be what the card says now.
    await summary.load(userId);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // The same seed the discovery, matches and feed data sources derive
    // from a user id, so members see themselves in the colours others do.
    final pair = AvatarPalette.forSeed(
      profile.userId.codeUnits.fold<int>(0, (a, b) => a + b),
    );

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pair,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            profile.name.characters.firstOrNull ?? '',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.name}, ${profile.age}',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.plumStrong,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: colors.teal),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      profile.city,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
