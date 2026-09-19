import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../messaging/presentation/screens/chat_screen.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import '../bloc/matching_cubit.dart';

/// A single self-contained screen — unlike auth/profile, discovery has no
/// multi-screen wizard state to share, so `MatchingCubit` is provided
/// right here (not at the app root). Revisiting this screen starts a
/// fresh cubit, which is the right behavior for a feed anyway.
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<MatchingCubit>(), child: const _DiscoveryView());
  }
}

class _DiscoveryView extends StatefulWidget {
  const _DiscoveryView();

  @override
  State<_DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<_DiscoveryView> {
  @override
  void initState() {
    super.initState();
    context.read<MatchingCubit>().loadCandidates();
  }

  Future<void> _openFilters(CandidateFilter current) async {
    final applied = await showModalBottomSheet<CandidateFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(initial: current),
    );
    if (applied != null && mounted) {
      context.read<MatchingCubit>().loadCandidates(filter: applied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          BlocBuilder<MatchingCubit, MatchingState>(
            builder: (context, state) {
              final filter = state is MatchingLoaded ? state.filter : CandidateFilter.empty;
              return IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilters(filter),
                tooltip: 'Filtreler',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<MatchingCubit, MatchingState>(
        listenWhen: (previous, current) =>
            current is MatchingLoaded &&
            (previous is! MatchingLoaded ||
                previous.justMatched != current.justMatched ||
                previous.swipeError != current.swipeError),
        listener: (context, state) {
          if (state is! MatchingLoaded) return;
          if (state.justMatched != null) {
            _showMatchDialog(context, state.justMatched!);
          }
          if (state.swipeError != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.swipeError!)));
          }
        },
        builder: (context, state) {
          if (state is MatchingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MatchingError) {
            return Center(
              child: Text(state.message, style: textTheme.bodyLarge?.copyWith(color: colors.rose)),
            );
          }
          final loaded = state as MatchingLoaded;
          final candidate = loaded.current;

          if (candidate == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_off_outlined, size: 40, color: colors.inkSoft),
                    const SizedBox(height: 12),
                    Text(
                      'Şu an gösterilecek aday kalmadı.',
                      style: textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Filtreleri genişletmeyi deneyebilirsin.',
                      style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _openFilters(loaded.filter),
                      child: const Text('Filtreleri değiştir'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(child: _CandidateCard(candidate: candidate)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loaded.isSwiping
                            ? null
                            : () => context.read<MatchingCubit>().swipe(SwipeAction.pass),
                        icon: const Icon(Icons.close),
                        label: const Text('Geç'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.inkSoft,
                          side: BorderSide(color: colors.line),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: loaded.isSwiping
                            ? null
                            : () => context.read<MatchingCubit>().swipe(SwipeAction.like),
                        icon: const Icon(Icons.favorite_outline),
                        label: const Text('Beğen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMatchDialog(BuildContext context, Match match) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Eşleştiniz! ✨', style: textTheme.titleLarge),
        content: Text(
          '${match.candidate.name} ile karşılıklı beğendiniz.',
          style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(
                '/chat',
                extra: ChatRouteArgs(
                  matchId: match.id,
                  otherPartyName: match.candidate.name,
                  otherPartyAvatarSeed: match.candidate.avatarColorSeed,
                ),
              );
            },
            child: const Text('Sohbete başla'),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});
  final Candidate candidate;

  static const _avatarColors = [Color(0xFF5B2C55), Color(0xFFB8863F), Color(0xFFA9726B)];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = _avatarColors[candidate.avatarColorSeed % _avatarColors.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: avatarColor,
              child: Text(
                candidate.name.characters.first,
                style: textTheme.displayLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('${candidate.name}, ${candidate.age}', style: textTheme.titleLarge),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                candidate.city,
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.plumTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  candidate.intent == CandidateIntent.marriage ? 'Evlilik' : 'Henüz emin değil',
                  style: textTheme.labelSmall?.copyWith(color: colors.plumStrong),
                ),
              ),
            ),
            if (candidate.bio != null) ...[
              const SizedBox(height: 16),
              Text(
                candidate.bio!,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final CandidateFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _cityController;
  late RangeValues _ageRange;
  CandidateIntent? _intent;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initial.city ?? '');
    _ageRange = RangeValues(
      (widget.initial.minAge ?? 20).toDouble(),
      (widget.initial.maxAge ?? 45).toDouble(),
    );
    _intent = widget.initial.intent;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtreler', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'ŞEHİR'),
          ),
          const SizedBox(height: 16),
          Text(
            'YAŞ ARALIĞI: ${_ageRange.start.round()}–${_ageRange.end.round()}',
            style: textTheme.labelSmall?.copyWith(color: colors.inkSoft),
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: colors.plum,
            labels: RangeLabels('${_ageRange.start.round()}', '${_ageRange.end.round()}'),
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 8),
          Text('NİYET', style: textTheme.labelSmall?.copyWith(color: colors.inkSoft)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Farketmez'),
                selected: _intent == null,
                onSelected: (_) => setState(() => _intent = null),
              ),
              ChoiceChip(
                label: const Text('Evlilik'),
                selected: _intent == CandidateIntent.marriage,
                onSelected: (_) => setState(() => _intent = CandidateIntent.marriage),
              ),
              ChoiceChip(
                label: const Text('Henüz emin değil'),
                selected: _intent == CandidateIntent.notSureYet,
                onSelected: (_) => setState(() => _intent = CandidateIntent.notSureYet),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(
                CandidateFilter(
                  city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
                  minAge: _ageRange.start.round(),
                  maxAge: _ageRange.end.round(),
                  intent: _intent,
                ),
              );
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }
}
