import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Hesap & veri',
          ),
        ],
      ),
      body: BlocBuilder<GuardianCubit, GuardianState>(
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
                child: Text(
                  'Yakının henüz seninle hiçbir eşleşmeyi paylaşmadı. '
                  'Paylaştığında burada görünecek.',
                  style: textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _VisibleMatchCard(match: matches[index]),
          );
        },
      ),
    );
  }
}

class _VisibleMatchCard extends StatelessWidget {
  const _VisibleMatchCard({required this.match});
  final FamilyVisibleMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.plum,
              child: Text(
                match.candidateName.characters.first,
                style: textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${match.candidateName}, ${match.candidateAge}',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.candidateCity,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.brassTint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                match.statusLabel,
                style: textTheme.labelSmall?.copyWith(color: colors.plumStrong),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
