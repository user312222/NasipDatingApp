import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft, blurred color blobs behind a wizard screen so registration steps
/// share the same "alive" backdrop as the discovery screen instead of a
/// flat cream page.
class WizardBackdrop extends StatelessWidget {
  const WizardBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Clip.none lets the top glow keep going behind the (transparent) app
    // bar instead of being cut off in a hard line at the body's edge.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: _Glow(color: colors.accent, size: 280),
        ),
        Positioned(
          bottom: -60,
          left: -80,
          child: _Glow(color: colors.teal, size: 280),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

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
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar — "you're on step [current] of [total]".
class WizardProgress extends StatelessWidget {
  const WizardProgress({super.key, required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: i <= current
                    ? LinearGradient(colors: [colors.plumFill, colors.accent])
                    : null,
                color: i <= current ? null : colors.line,
              ),
            ),
          ),
          if (i < total) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

/// Icon badge + Fraunces title + subtitle, with an optional progress bar
/// above. The badge pops in with a small scale animation on first build.
class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.step,
    this.totalSteps,
    this.centered = false,
    this.leading,
  });

  /// Shown instead of the gradient icon badge when set (e.g. [BrandLogo]
  /// on the welcome screen).
  final Widget? leading;

  final IconData icon;
  final String title;
  final String? subtitle;
  final int? step;
  final int? totalSteps;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        if (step != null && totalSteps != null) ...[
          WizardProgress(current: step!, total: totalSteps!),
          const SizedBox(height: 22),
        ],
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.scale(
            scale: t,
            child: Opacity(opacity: t.clamp(0, 1), child: child),
          ),
          child:
              leading ??
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.plumFill, colors.accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.plumFill.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.headlineMedium?.copyWith(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: colors.plumStrong,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
          ),
        ],
      ],
    );
  }
}

/// Full-width primary action: plum→rose gradient, colored shadow, press
/// scale. [loading] swaps the label for a spinner and disables taps;
/// a null [onPressed] renders the muted disabled state.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final enabled = _enabled;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: enabled || widget.loading
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [colors.plumFill, colors.accent],
                  )
                : null,
            color: enabled || widget.loading ? null : colors.line,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colors.plumFill.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: enabled ? widget.onPressed : null,
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: textTheme.labelLarge?.copyWith(
                          color: enabled ? Colors.white : colors.inkSoft,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable card for single-choice steps (account type, photo
/// visibility, intent). The selected state animates to a tinted fill with
/// a plum border and a check badge.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colors.plumTint : colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colors.plum : colors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.plumFill.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? colors.plumFill : colors.plumTint,
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? Colors.white : colors.plum,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.plumStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.plumFill : Colors.transparent,
                border: Border.all(
                  color: selected ? colors.plum : colors.inkSoft,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Safe-area + padding + scroll wrapper for wizard steps that pin their
/// primary button to the bottom with a `Spacer`: the content fills the
/// screen when it fits and scrolls instead of overflowing on short phones.
class WizardBody extends StatelessWidget {
  const WizardBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ],
      ),
    );
  }
}

/// A rounded content card with an icon badge and title — used by the
/// settings and family screens for their grouped sections. [danger] tints
/// the badge/border rose for destructive areas.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.child,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? child;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final accent = danger ? colors.rose : colors.plum;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: danger ? colors.rose.withValues(alpha: 0.45) : colors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: danger ? colors.roseSoft : null,
                  gradient: danger
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors.brandGradient,
                        ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: danger ? accent : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.plumStrong,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: 10),
            Text(
              body!,
              style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

/// The round chip every app-bar control sits in (back arrow, actions,
/// overflow menus), so the top of each screen reads as one family instead
/// of bare glyphs. [primary] is the single most important action on a
/// screen and gets the brand gradient.
class ChromeChip extends StatelessWidget {
  const ChromeChip({
    super.key,
    required this.icon,
    this.primary = false,
    this.size = 40,
  });

  final IconData icon;
  final bool primary;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary ? null : colors.surface,
        gradient: primary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors.brandGradient,
              )
            : null,
        border: primary ? null : Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: (primary ? colors.accent : colors.plumFill).withValues(
              alpha: primary ? 0.38 : 0.12,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: primary ? Colors.white : colors.plumStrong,
      ),
    );
  }
}

/// A tappable [ChromeChip] for app-bar actions.
class ChromeIconButton extends StatelessWidget {
  const ChromeIconButton({
    super.key,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 26,
          child: ChromeChip(icon: icon, primary: primary),
        ),
      ),
    );
  }
}

/// The Bi Nasip logo on a white rounded tile. The artwork has an opaque
/// white background, so it always sits on white rather than directly on the
/// cream (or dark) page.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 150});

  static const assetPath = 'assets/images/logo.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: colors.plumFill.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        semanticLabel: 'Bi Nasip logosu',
      ),
    );
  }
}
