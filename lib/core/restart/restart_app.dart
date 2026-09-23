import 'package:flutter/material.dart';

import '../di/injection_container.dart';
import '../router/app_router.dart';

/// Wraps the whole app so it can be torn down and rebuilt from scratch:
/// re-registers every dependency (dropping all in-memory mock state) and
/// gives the tree a new key so the root cubits are recreated. Used after
/// FR-7.1 account deletion — nothing of the old session may survive it.
class RestartApp extends StatefulWidget {
  const RestartApp({super.key, required this.child});

  final Widget child;

  static Future<void> restart(BuildContext context) {
    return context.findAncestorStateOfType<_RestartAppState>()!._restart();
  }

  @override
  State<RestartApp> createState() => _RestartAppState();
}

class _RestartAppState extends State<RestartApp> {
  Key _key = UniqueKey();

  Future<void> _restart() async {
    appRouter.go('/');
    await sl.reset();
    await initDependencies();
    if (!mounted) return;
    setState(() => _key = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
