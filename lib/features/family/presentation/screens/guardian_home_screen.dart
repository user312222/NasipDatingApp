import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/family_visible_match.dart';
import '../bloc/guardian_cubit.dart';

/// FR-8.5/8.6: strictly read-only. There is deliberately no like/pass
/// button, no chat entry point, and no discovery route anywhere reachable
/// from here.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  @override
  void initState() {
    super.initState();
    final userId =
        context.read<AuthCubit>().currentUser?.id ?? 'unknown_guardian';
    context.read<GuardianCubit>().loadMatches(userId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakınımın Eşleşmeleri'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChromeIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Hesap & veri',
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: WizardBackdrop(
        child: BlocBuilder<GuardianCubit, GuardianState>(
          builder: (context, state) {
            if (state is GuardianMatchesLoading || state is GuardianLinked) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GuardianMatchesFailed) {
              return Center(
                child: Text(
                  state.message,
                  style: textTheme.bodyLarge?.copyWith(color: colors.rose),
                ),
              );
            }
            final matches = state is GuardianMatchesLoaded
                ? state.matches
                : <FamilyVisibleMatch>[];
            if (matches.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SectionCard(
                    icon: Icons.visibility_off_outlined,
                    title: 'Henüz paylaşılan eşleşme yok',
                    body:
                        'Yakının henüz seninle hiçbir eşleşmeyi paylaşmadı. '
                        'Paylaştığında burada görünecek.',
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  VisibleMatchCard(match: matches[index]),
            );
          },
        ),
      ),
    );
  }
}

class VisibleMatchCard extends StatelessWidget {
  const VisibleMatchCard({super.key, required this.match});
  final FamilyVisibleMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // The guardian-facing type deliberately carries no avatar seed (see
    // FamilyVisibleMatch), so derive a stable color from the name.
    final palette = AvatarPalette.forSeed(
      match.candidateName.codeUnits.fold(0, (a, b) => a + b),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
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
              match.candidateName.characters.first,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: Colors.white,
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
                  '${match.candidateName}, ${match.candidateAge}',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.plumStrong,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: colors.rose,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        match.candidateCity,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: colors.plumFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              match.statusLabel,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
