import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
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
      body: BlocBuilder<FamilyLinkCubit, FamilyLinkState>(
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
              Text('Aile kodun', style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Bir yakınına bu kodu ver — kendi Bi Nasip hesabını "yakınımı takip '
                'ediyorum" olarak açıp bu kodla bağlanabilir.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: colors.plumTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SelectableText(
                    loaded.inviteCode,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colors.plumStrong,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Eşleşmelerin', style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Sadece "aileme göster" dediklerini bağlı yakının görebilir; mesaj '
                'içeriğini asla göremez.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 8),
              if (loaded.matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Henüz eşleşmen yok.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                )
              else
                ...loaded.matches.map(
                  (m) => Card(
                    child: SwitchListTile(
                      value: m.visibleToFamily,
                      activeThumbColor: colors.plum,
                      onChanged: (v) => context
                          .read<FamilyLinkCubit>()
                          .setVisible(matchId: m.id, visible: v),
                      title: Text(
                        '${m.candidate.name}, ${m.candidate.age}',
                        style: textTheme.titleSmall,
                      ),
                      subtitle: Text('${m.candidate.city} · aileme göster'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
