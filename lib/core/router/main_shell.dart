import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

/// The signed-in single user's home: four tabs behind a floating bottom
/// bar. Each tab keeps its own navigation stack and state (go_router's
/// `StatefulShellRoute.indexedStack`), so switching away from Discovery
/// and back doesn't reload the candidates. Full-screen pages (chat, family
/// settings, ...) are top-level routes and cover the bar.
class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    this.badges = const {},
    this.onTabSelected,
  });

  final StatefulNavigationShell navigationShell;

  /// Tabs that show a small "something waiting" dot: tab index -> what the
  /// dot means, read out after the tab's name ("Eşleşmeler, yeni mesaj
  /// var").
  final Map<int, String> badges;

  /// Called with the index every time a tab is tapped (e.g. to refresh it).
  final ValueChanged<int>? onTabSelected;

  static const tabs = [
    _Tab('Keşfet', Icons.explore_outlined, Icons.explore_rounded),
    _Tab('Günün Sorusu', Icons.forum_outlined, Icons.forum_rounded),
    _Tab(
      'Eşleşmeler',
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
    ),
    _Tab('Hesap', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(color: colors.line),
              boxShadow: [
                BoxShadow(
                  color: colors.plumFill.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _TabButton(
                      tab: tabs[i],
                      selected: i == navigationShell.currentIndex,
                      badge: badges[i],
                      // Tapping the tab you're already on goes back to its
                      // root, the usual bottom-bar behaviour.
                      onTap: () {
                        onTabSelected?.call(i);
                        navigationShell.goBranch(
                          i,
                          initialLocation: i == navigationShell.currentIndex,
                        );
                      },
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

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _Tab tab;
  final bool selected;

  /// Non-null shows the dot; the text is its screen-reader description.
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? colors.plum : colors.inkSoft;

    return Semantics(
      button: true,
      selected: selected,
      label: badge == null ? tab.label : '${tab.label}, $badge',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? colors.plumTint : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? tab.selectedIcon : tab.icon,
                    size: 22,
                    color: color,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        key: const ValueKey('tab_badge'),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab.label,
                maxLines: 1,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  letterSpacing: 0,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
