import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/avatar_palette.dart';
import '../../domain/entities/candidate.dart';
import 'show_family_switch_row.dart';

/// The mutual-like celebration (FR-4.2): a gradient header in the
/// candidate's own palette with a pulsing heart, replacing the plain
/// `AlertDialog`. The pulse is a looping `AnimationController` that lives
/// only as long as the dialog is on screen.
///
/// It also carries the per-match "aileme göster" switch (FR-8.4), off by
/// default like every other visibility setting (FR-3.2).
class MatchCelebration extends StatefulWidget {
  const MatchCelebration({
    super.key,
    required this.candidate,
    required this.onLater,
    required this.onChat,
    required this.onShowFamilyChanged,
  });

  final Candidate candidate;
  final VoidCallback onLater;
  final VoidCallback onChat;

  /// Saves the "aileme göster" choice; completes with false if it could
  /// not be saved, and the switch goes back to where it was.
  final Future<bool> Function(bool visible) onShowFamilyChanged;

  @override
  State<MatchCelebration> createState() => _MatchCelebrationState();
}

class _MatchCelebrationState extends State<MatchCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool _showFamily = false;
  bool _savingFamily = false;
  bool _familyFailed = false;

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

  Future<void> _setShowFamily(bool value) async {
    setState(() {
      _showFamily = value;
      _savingFamily = true;
      _familyFailed = false;
    });
    final saved = await widget.onShowFamilyChanged(value);
    if (!mounted) return;
    setState(() {
      _savingFamily = false;
      if (!saved) {
        _showFamily = !value;
        _familyFailed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final pair = AvatarPalette.forSeed(widget.candidate.avatarColorSeed);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
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
                  height: 160,
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
                          color: colors.plumFill,
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
                      const SizedBox(height: 18),
                      ShowFamilySwitchRow(
                        value: _showFamily,
                        failed: _familyFailed,
                        onChanged: _savingFamily ? null : _setShowFamily,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.onChat,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.plumFill,
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
      ),
    );
  }
}
