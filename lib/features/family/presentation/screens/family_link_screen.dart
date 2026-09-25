import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/family_link_cubit.dart';

/// The single user's side of FR-8: their invite code and a per-match
/// "aileme göster" switch (default off, FR-8.4). Self-provided cubit —
/// no cross-screen flow state to keep.
class FamilyLinkScreen extends StatelessWidget {
  const FamilyLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().currentUser?.id ?? 'unknown_user';
    return BlocProvider(
      create: (_) => sl<FamilyLinkCubit>()..load(userId),
      child: const _FamilyLinkView(),
    );
  }
}

class _FamilyLinkView extends StatelessWidget {
  const _FamilyLinkView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Bağlantısı')),
      body: WizardBackdrop(
        child: BlocBuilder<FamilyLinkCubit, FamilyLinkState>(
          builder: (context, state) {
            if (state is FamilyLinkLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FamilyLinkError) {
              return Center(
                child: Text(
                  state.message,
                  style: textTheme.bodyLarge?.copyWith(color: colors.rose),
                ),
              );
            }
            final loaded = state as FamilyLinkLoaded;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _InviteCodeCard(code: loaded.inviteCode),
                const SizedBox(height: 24),
                Text(
                  'Eşleşmelerin',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    color: colors.plumStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sadece "aileme göster" dediklerini bağlı yakının görebilir; mesaj '
                  'içeriğini asla göremez.',
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
                const SizedBox(height: 14),
                if (loaded.matches.isEmpty)
                  SectionCard(
                    icon: Icons.favorite_border_rounded,
                    title: 'Henüz eşleşmen yok.',
                    body:
                        'Eşleştiğin kişiler burada listelenir; hangisini '
                        'ailene göstereceğine sen karar verirsin.',
                  )
                else
                  for (final m in loaded.matches) ...[
                    _MatchSwitchTile(
                      name: '${m.candidate.name}, ${m.candidate.age}',
                      city: m.candidate.city,
                      initial: m.candidate.name.characters.first,
                      palette: AvatarPalette.forSeed(
                        m.candidate.avatarColorSeed,
                      ),
                      value: m.visibleToFamily,
                      onChanged: (v) => context
                          .read<FamilyLinkCubit>()
                          .setVisible(matchId: m.id, visible: v),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.plumFill, const Color(0xFFC17B72)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.plumFill.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Aile kodun',
                style: textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bir yakınına bu kodu ver — kendi Bi Nasip hesabını "yakınımı takip '
            'ediyorum" olarak açıp bu kodla bağlanabilir.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: SelectableText(
                code,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kod kopyalandı.')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Kopyala'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchSwitchTile extends StatelessWidget {
  const _MatchSwitchTile({
    required this.name,
    required this.city,
    required this.initial,
    required this.palette,
    required this.value,
    required this.onChanged,
  });

  final String name;
  final String city;
  final String initial;
  final List<Color> palette;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: value ? colors.plumTint : colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: value ? colors.plum : colors.line,
          width: value ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.plumStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$city · aileme göster',
                  style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: colors.plumFill,
          ),
        ],
      ),
    );
  }
}
