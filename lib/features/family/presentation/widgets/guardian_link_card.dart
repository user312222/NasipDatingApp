import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/relationship.dart';
import '../bloc/current_link_cubit.dart';

/// The "Bağlı hesap" card on a guardian's settings screen: whose account
/// they follow, and the deliberate way to move to another one (FR-8.3: a
/// guardian is linked to one account at a time).
class GuardianLinkCard extends StatelessWidget {
  const GuardianLinkCard({
    super.key,
    required this.userId,
    this.enabled = true,
  });

  final String userId;

  /// False while the account is being signed out or deleted.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (_) => sl<CurrentLinkCubit>()..load(userId),
      child: BlocBuilder<CurrentLinkCubit, CurrentLinkState>(
        builder: (context, state) {
          final link = state is CurrentLinkFound ? state.link : null;
          return SectionCard(
            icon: Icons.family_restroom_rounded,
            title: 'Bağlı hesap',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (link != null) ...[
                  Text(
                    link.singleName ?? 'Adı okunamadı',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.plumStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Yakınlığın: ${link.relationship.label}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  state is CurrentLinkNone
                      ? 'Henüz bir hesaba bağlı değilsin. Yakınından aldığın '
                            'aile koduyla bağlanabilirsin.'
                      : 'Yanlış koda bağlandıysan ya da başka bir yakınını takip '
                            'edeceksen, yeni bir aile koduyla bağlantını '
                            'değiştirebilirsin. Aynı anda yalnızca bir hesaba '
                            'bağlı olabilirsin.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: enabled
                      ? () => context.push('/guardian/link')
                      : null,
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: Text(
                    state is CurrentLinkNone
                        ? 'Bir hesaba bağlan'
                        : 'Bağlı hesabı değiştir',
                  ),
                  style: sectionActionStyle(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
