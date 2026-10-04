import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/router/main_shell.dart';
import 'package:binasip/theme/app_colors.dart';
import 'package:binasip/theme/app_theme.dart';

class _CounterTab extends StatefulWidget {
  const _CounterTab(this.name);
  final String name;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('${widget.name}: $_count'),
        TextButton(
          onPressed: () => setState(() => _count++),
          child: const Text('artır'),
        ),
        TextButton(
          onPressed: () => context.push('/full'),
          child: const Text('tam ekran'),
        ),
      ],
    ),
  );
}

GoRouter _router({
  Map<int, String> badges = const {},
  ValueChanged<int>? onTabSelected,
}) => GoRouter(
  initialLocation: '/discover',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(
        navigationShell: shell,
        badges: badges,
        onTabSelected: onTabSelected,
      ),
      branches: [
        for (final path in ['/discover', '/feed', '/matches', '/account'])
          StatefulShellBranch(
            routes: [GoRoute(path: path, builder: (_, _) => _CounterTab(path))],
          ),
      ],
    ),
    GoRoute(
      path: '/full',
      builder: (_, _) => const Scaffold(body: Text('tam ekran sayfa')),
    ),
  ],
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Map<int, String> badges = const {},
    ValueChanged<int>? onTabSelected,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: theme ?? AppTheme.light(),
        routerConfig: _router(badges: badges, onTabSelected: onTabSelected),
      ),
    );
    await tester.pumpAndSettle();
  }

  // How much the selected tab's pill stands out from the bar behind it, as
  // a WCAG-style contrast ratio (1.0 = invisible).
  double pillContrast(WidgetTester tester) {
    final colors = Theme.of(tester.element(find.byType(MainShell)))
        .extension<AppColors>()!;
    final pill = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.decoration! as BoxDecoration).color!)
        .firstWhere((c) => c.a > 0);
    final onBar = Color.alphaBlend(pill, colors.surface);
    final a = onBar.computeLuminance() + 0.05;
    final b = colors.surface.computeLuminance() + 0.05;
    return a > b ? a / b : b / a;
  }

  testWidgets('the selected tab is marked clearly in both themes', (
    tester,
  ) async {
    await pump(tester);
    expect(pillContrast(tester), greaterThan(1.15));

    await pump(tester, theme: AppTheme.dark());
    expect(pillContrast(tester), greaterThan(1.3));
  });

  testWidgets('shows the four tabs and starts on Keşfet', (tester) async {
    await pump(tester);

    for (final tab in MainShell.tabs) {
      expect(find.bySemanticsLabel(tab.label), findsOneWidget);
    }
    expect(find.text('/discover: 0'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
  });

  testWidgets('tapping a tab switches to its screen', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Eşleşmeler'));
    await tester.pumpAndSettle();
    expect(find.text('/matches: 0'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);

    await tester.tap(find.text('Günün Sorusu'));
    await tester.pumpAndSettle();
    expect(find.text('/feed: 0'), findsOneWidget);
  });

  testWidgets('each tab keeps its state while another is open', (tester) async {
    await pump(tester);

    await tester.tap(find.text('artır'));
    await tester.tap(find.text('artır'));
    await tester.pump();
    expect(find.text('/discover: 2'), findsOneWidget);

    await tester.tap(find.text('Hesap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keşfet'));
    await tester.pumpAndSettle();

    expect(find.text('/discover: 2'), findsOneWidget);
  });

  testWidgets('a full-screen page covers the bar', (tester) async {
    await pump(tester);

    await tester.tap(find.text('tam ekran'));
    await tester.pumpAndSettle();

    expect(find.text('tam ekran sayfa'), findsOneWidget);
    expect(find.text('Hesap'), findsNothing);
  });

  testWidgets('a badged tab shows the dot and says so to screen readers', (
    tester,
  ) async {
    await pump(tester, badges: {2: 'yeni mesaj var'});

    expect(find.byKey(const ValueKey('tab_badge')), findsOneWidget);
    expect(find.bySemanticsLabel('Eşleşmeler, yeni mesaj var'), findsOneWidget);
  });

  testWidgets('each badged tab gets its own dot and description', (
    tester,
  ) async {
    await pump(
      tester,
      badges: {1: 'bugünün sorusu seni bekliyor', 2: 'yeni mesaj var'},
    );

    expect(find.byKey(const ValueKey('tab_badge')), findsNWidgets(2));
    expect(
      find.bySemanticsLabel('Günün Sorusu, bugünün sorusu seni bekliyor'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Eşleşmeler, yeni mesaj var'), findsOneWidget);
  });

  testWidgets('no dot without a badge', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('tab_badge')), findsNothing);
  });

  testWidgets('reports which tab was tapped', (tester) async {
    final tapped = <int>[];
    await pump(tester, onTabSelected: tapped.add);

    await tester.tap(find.text('Eşleşmeler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eşleşmeler'));
    await tester.pumpAndSettle();

    expect(tapped, [2, 2]);
  });
}
