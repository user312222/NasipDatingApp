import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../messaging/presentation/screens/chat_screen.dart';
import '../../../safety/presentation/widgets/safety_menu_button.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/candidate_filter.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_outcome.dart';
import '../bloc/matching_cubit.dart';
import '../widgets/crescent_motif_painter.dart';

/// A single self-contained screen — unlike auth/profile, discovery has no
/// multi-screen wizard state to share, so `MatchingCubit` is provided
/// right here (not at the app root). Revisiting this screen starts a
/// fresh cubit, which is the right behavior for a feed anyway.
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MatchingCubit>(),
      child: const _DiscoveryView(),
    );
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
        title: Text(
          'Keşfet',
          style: textTheme.displayMedium?.copyWith(
            fontSize: 26,
            color: colors.plumStrong,
          ),
        ),
        actions: [
          BlocBuilder<MatchingCubit, MatchingState>(
            builder: (context, state) {
              final filter = state is MatchingLoaded
                  ? state.filter
                  : CandidateFilter.empty;
              return _ChromeIconButton(
                icon: Icons.tune,
                onPressed: () => _openFilters(filter),
                tooltip: 'Filtreler',
                primary: true,
              );
            },
          ),
          _ChromeMenuButton(
            items: [
              _ChromeMenuItem(
                icon: Icons.settings_outlined,
                label: 'Hesap & veri',
                onTap: () => context.push('/settings'),
              ),
              _ChromeMenuItem(
                icon: Icons.family_restroom_outlined,
                label: 'Aile bağlantısı',
                onTap: () => context.push('/family/settings'),
              ),
            ],
          ),
          const SizedBox(width: 10),
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
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.swipeError!)));
          }
        },
        builder: (context, state) {
          if (state is MatchingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MatchingError) {
            return Center(
              child: Text(
                state.message,
                style: textTheme.bodyLarge?.copyWith(color: colors.rose),
              ),
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
                    Icon(
                      Icons.explore_off_outlined,
                      size: 40,
                      color: colors.inkSoft,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Şu an gösterilecek aday kalmadı.',
                      style: textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Filtreleri genişletmeyi deneyebilirsin.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                      ),
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

          final pair = _CandidateCard.paletteFor(candidate);

          return Stack(
            children: [
              Positioned(
                top: -30,
                right: -50,
                child: _BackgroundGlow(color: pair.first, size: 220),
              ),
              Positioned(
                bottom: 30,
                left: -60,
                child: _BackgroundGlow(color: pair.last, size: 220),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.94,
                        end: 1,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _SwipeableCard(
                    key: ValueKey(candidate.id),
                    candidate: candidate,
                    isSwiping: loaded.isSwiping,
                    onPass: () => context.read<MatchingCubit>().swipe(
                      SwipeAction.pass,
                    ),
                    onLike: () => context.read<MatchingCubit>().swipe(
                      SwipeAction.like,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMatchDialog(BuildContext context, Match match) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (dialogContext, _, _) => _MatchCelebration(
        candidate: match.candidate,
        onLater: () => Navigator.of(dialogContext).pop(),
        onChat: () {
          Navigator.of(dialogContext).pop();
          context.push(
            '/chat',
            extra: ChatRouteArgs(
              matchId: match.id,
              otherPartyUserId: match.candidate.id,
              otherPartyName: match.candidate.name,
              otherPartyAvatarSeed: match.candidate.avatarColorSeed,
            ),
          );
        },
      ),
    );
  }
}

/// The mutual-like celebration (FR-4.2): a gradient header in the
/// candidate's own palette with a pulsing heart, replacing the plain
/// `AlertDialog`. The pulse is a looping `AnimationController` that lives
/// only as long as the dialog is on screen.
class _MatchCelebration extends StatefulWidget {
  const _MatchCelebration({
    required this.candidate,
    required this.onLater,
    required this.onChat,
  });

  final Candidate candidate;
  final VoidCallback onLater;
  final VoidCallback onChat;

  @override
  State<_MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<_MatchCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pair = _CandidateCard.paletteFor(widget.candidate);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(30),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: pair,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) {
                        final t = _pulse.value;
                        return Container(
                          width: 84 + 90 * t,
                          height: 84 + 90 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: 0.28 * (1 - t),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 44,
                        color: colors.plum,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'Eşleştiniz!',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.plumStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.candidate.name} ile karşılıklı beğendiniz.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onChat,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.plum,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Sohbete başla'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: widget.onLater,
                      child: Text(
                        'Şimdi değil',
                        style: TextStyle(color: colors.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An app-bar action wrapped in a circle instead of a flat monochrome
/// icon — echoes the candidate card's circular action buttons so the page
/// chrome and the card read as one cohesive, colorful design. [primary]
/// gives the single most-used action (filters, on this screen) a solid
/// fill so it doesn't read as identical/interchangeable with the rest —
/// three same-toned circles in a row was the specific complaint this
/// fixes (2026-09-22).
class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: primary ? colors.plum : colors.plumTint,
          shape: const CircleBorder(),
          elevation: primary ? 3 : 0,
          shadowColor: colors.plumStrong.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                size: 20,
                color: primary ? Colors.white : colors.plumStrong,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single overflow entry for [_ChromeMenuButton].
class _ChromeMenuItem {
  const _ChromeMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Groups the less-frequently-used app-bar actions (account settings,
/// family link) behind a single tinted overflow button instead of giving
/// each its own same-toned circle — see [_ChromeIconButton]'s doc comment
/// for why that repetition was the problem.
class _ChromeMenuButton extends StatelessWidget {
  const _ChromeMenuButton({required this.items});

  final List<_ChromeMenuItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: PopupMenuButton<VoidCallback>(
        tooltip: 'Diğer',
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.line),
        ),
        onSelected: (action) => action(),
        itemBuilder: (context) => [
          for (final item in items)
            PopupMenuItem<VoidCallback>(
              value: item.onTap,
              child: Row(
                children: [
                  Icon(item.icon, size: 19, color: colors.plumStrong),
                  const SizedBox(width: 12),
                  Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
        ],
        child: Material(
          color: colors.plumTint,
          shape: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.more_horiz, size: 20, color: colors.plumStrong),
          ),
        ),
      ),
    );
  }
}

/// A soft, blurred-looking color blob behind the card — ties the page
/// background to the candidate's own illustration palette so the screen
/// feels like one continuous, colorful composition instead of a flat
/// cream backdrop with a colorful card dropped on top of it.
class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.42),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns the drag-to-decide gesture: the card follows the finger, rotates
/// slightly around its bottom edge (like a card pinned at the bottom), and
/// either flings off-screen past [_flingThreshold] or snaps back to
/// center. Tapping the pass/like buttons runs the same fling animation
/// programmatically, so button taps and drags feel identical. The actual
/// `MatchingCubit.swipe()` call (passed in as [onLike]/[onPass]) only
/// fires once the fling animation finishes — the card is already visually
/// off-screen by then, so the async Firestore round-trip never stalls the
/// animation.
class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    super.key,
    required this.candidate,
    required this.isSwiping,
    required this.onLike,
    required this.onPass,
  });

  final Candidate candidate;
  final bool isSwiping;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  static const _flingThreshold = 110.0;

  late final AnimationController _controller;
  Animation<Offset>? _animation;
  Offset _drag = Offset.zero;
  bool _released = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 260),
          )
          ..addListener(() {
            final animation = _animation;
            if (animation != null) setState(() => _drag = animation.value);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(Offset target, {VoidCallback? onDone}) {
    _animation = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..reset()
      ..forward().whenComplete(() => onDone?.call());
  }

  void _fling(bool liked) {
    if (widget.isSwiping || _released) return;
    _released = true;
    final width = MediaQuery.of(context).size.width;
    _animateTo(
      Offset(liked ? width : -width, _drag.dy * 0.3),
      onDone: liked ? widget.onLike : widget.onPass,
    );
  }

  void _snapBack() => _animateTo(Offset.zero);

  bool get _inputEnabled => !widget.isSwiping && !_released;

  @override
  Widget build(BuildContext context) {
    final dragProgress = (_drag.dx / _flingThreshold).clamp(-1.0, 1.0);
    final angle = (_drag.dx / 1400).clamp(-0.32, 0.32);

    return GestureDetector(
      onPanUpdate: _inputEnabled
          ? (details) => setState(() => _drag += details.delta)
          : null,
      onPanEnd: _inputEnabled
          ? (details) {
              if (_drag.dx.abs() > _flingThreshold) {
                _fling(_drag.dx > 0);
              } else {
                _snapBack();
              }
            }
          : null,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: _CandidateCard(
            candidate: widget.candidate,
            isSwiping: widget.isSwiping,
            dragProgress: dragProgress,
            onPass: () => _fling(false),
            onLike: () => _fling(true),
          ),
        ),
      ),
    );
  }
}

/// Redesigned per the user's reference (2026-09-22): a full-bleed
/// illustration area up top (standing in for a real photo — FR-3 privacy
/// means the actual photo only ever renders once the candidate's chosen
/// visibility allows it, so this deliberately stays illustrative, never a
/// real face) with an info panel below, and circular like/pass buttons
/// overlapping the card's bottom edge instead of separate full-width
/// buttons. This widget's own `Stack` uses `clipBehavior: Clip.none` so
/// the buttons can render outside the card's bounds — the extra bottom
/// padding in `DiscoveryScreen.build` (`fromLTRB(20, 20, 20, 40)`) is what
/// leaves room for them to actually be visible rather than clipped by the
/// screen edge.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.onLike,
    required this.onPass,
    required this.isSwiping,
    this.dragProgress = 0,
  });

  final Candidate candidate;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final bool isSwiping;

  /// -1 (dragged toward "Geç") .. 1 (dragged toward "Beğen") — drives the
  /// stamp overlays below. Supplied by `_SwipeableCard`, which owns the
  /// actual drag gesture; this widget stays presentational.
  final double dragProgress;

  /// Vivid two-color pairs (rather than one color darkened toward black)
  /// so the illustration reads as energetic/contemporary instead of a
  /// moody, aged gradient. Exposed via [paletteFor] so the background glow
  /// in `DiscoveryScreen` can echo the same palette behind the card.
  static const _illustrationPairs = [
    [Color(0xFF8A3F80), Color(0xFFD9A15C)], // plum -> warm brass-rose
    [Color(0xFFDDA646), Color(0xFF8A3F80)], // brass -> plum
    [Color(0xFFD2897D), Color(0xFF9C4590)], // rose -> plum-pink
    [Color(0xFF9C4590), Color(0xFFD9A15C)], // plum-pink -> brass
  ];

  static List<Color> paletteFor(Candidate candidate) =>
      _illustrationPairs[candidate.avatarColorSeed % _illustrationPairs.length];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pair = paletteFor(candidate);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.plumStrong.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 60,
                  child: _IllustrationArea(colorPair: pair, candidate: candidate),
                ),
                Expanded(
                  flex: 40,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: candidate.name,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: colors.plumStrong,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ', ${candidate.age}',
                                      style: TextStyle(color: colors.ink),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.plum,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                candidate.intent == CandidateIntent.marriage
                                    ? '✧ Evlilik'
                                    : 'Henüz emin değil',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: colors.rose,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              candidate.city,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (candidate.bio != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            candidate.bio!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Reserved so the overflowing circular action
                        // buttons (see the Positioned below) never sit on
                        // top of this text, whatever its length.
                        const Spacer(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (dragProgress > 0.08)
          Positioned(
            top: 26,
            left: 22,
            child: Opacity(
              opacity: dragProgress.clamp(0, 1),
              child: Transform.rotate(
                angle: -0.22,
                child: _SwipeStamp(label: 'BEĞEN', color: colors.plum),
              ),
            ),
          ),
        if (dragProgress < -0.08)
          Positioned(
            top: 26,
            right: 22,
            child: Opacity(
              opacity: (-dragProgress).clamp(0, 1),
              child: Transform.rotate(
                angle: 0.22,
                child: _SwipeStamp(label: 'GEÇ', color: colors.rose),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: SafetyMenuButton(
              key: ValueKey(candidate.id),
              targetUserId: candidate.id,
              targetName: candidate.name,
              onBlocked: () =>
                  context.read<MatchingCubit>().removeCandidate(candidate.id),
            ),
          ),
        ),
        Positioned(
          bottom: -28,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleActionButton(
                icon: Icons.close_rounded,
                iconColor: colors.rose,
                background: colors.roseSoft,
                onTap: isSwiping ? null : onPass,
                tooltip: 'Geç',
              ),
              const SizedBox(width: 18),
              _CircleActionButton(
                icon: Icons.favorite_rounded,
                iconColor: Colors.white,
                gradient: [colors.plum, const Color(0xFFC17B72)],
                onTap: isSwiping ? null : onLike,
                tooltip: 'Beğen',
                large: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "BEĞEN"/"GEÇ" badge that fades in as the card is dragged — the
/// classic drag-to-decide affordance the 2026-09-22 Figma exploration
/// settled on ("Keşif kartı sürükle-bırak deneyimi") before that work
/// paused on a tool rate limit; implemented directly in Flutter here.
class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// The illustration standing in for a candidate's photo — a gradient
/// tinted by [Candidate.avatarColorSeed] so different candidates read as
/// visually distinct, a single soft crescent for texture (see
/// `CrescentMotifPainter`'s doc comment — deliberately not a star shape,
/// to avoid any resemblance to an unrelated religious symbol), and the
/// initial letter as the only "content" — deliberately never a rendered
/// face.
class _IllustrationArea extends StatelessWidget {
  const _IllustrationArea({required this.colorPair, required this.candidate});

  final List<Color> colorPair;
  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -70,
            top: -60,
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: CrescentMotifPainter(
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 96,
            child: Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            left: 54,
            bottom: 60,
            child: Icon(
              Icons.auto_awesome,
              size: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Text(
                candidate.name.characters.first,
                style: textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Soft fade into the info panel below so the two areas feel like
          // one continuous card rather than an abrupt seam.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorPair.last.withValues(alpha: 0),
                    colorPair.last.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatefulWidget {
  const _CircleActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.tooltip,
    this.background,
    this.gradient,
    this.large = false,
  }) : assert(
         background != null || gradient != null,
         'either background or gradient must be provided',
       );

  final IconData icon;
  final Color iconColor;
  final Color? background;
  final List<Color>? gradient;
  final VoidCallback? onTap;
  final String tooltip;
  final bool large;

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

/// A quick press-down scale (see `build`'s `AnimatedScale`) gives the
/// button tactile "give" instead of only relying on `InkWell`'s ripple,
/// which was barely visible against these saturated fills.
class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.large ? 66.0 : 54.0;
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.86 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.gradient == null ? widget.background : null,
              gradient: widget.gradient == null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradient!,
                    ),
              boxShadow: [
                BoxShadow(
                  color: (widget.gradient?.first ?? widget.background!)
                      .withValues(alpha: 0.35),
                  blurRadius: widget.large ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: widget.large ? 30 : 24,
                ),
              ),
            ),
          ),
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
            labels: RangeLabels(
              '${_ageRange.start.round()}',
              '${_ageRange.end.round()}',
            ),
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 8),
          Text(
            'NİYET',
            style: textTheme.labelSmall?.copyWith(color: colors.inkSoft),
          ),
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
                onSelected: (_) =>
                    setState(() => _intent = CandidateIntent.marriage),
              ),
              ChoiceChip(
                label: const Text('Henüz emin değil'),
                selected: _intent == CandidateIntent.notSureYet,
                onSelected: (_) =>
                    setState(() => _intent = CandidateIntent.notSureYet),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(
                CandidateFilter(
                  city: _cityController.text.trim().isEmpty
                      ? null
                      : _cityController.text.trim(),
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
