import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/report_reason.dart';
import '../bloc/safety_cubit.dart';

/// FR-6.1/6.2: one "⋮" menu — Şikayet et / Engelle — that discovery cards
/// and the chat screen both drop into their app bars. Self-provides its
/// own [SafetyCubit]; the host only supplies who the target is and what
/// to do once they've been blocked ([onBlocked]).
class SafetyMenuButton extends StatelessWidget {
  const SafetyMenuButton({
    super.key,
    required this.targetUserId,
    required this.targetName,
    required this.onBlocked,
    this.trigger,
  });

  /// What opens the menu. Defaults to the round app-bar chip; flat lists
  /// (the feed) pass a bare icon instead.
  final Widget? trigger;

  final String targetUserId;
  final String targetName;
  final VoidCallback onBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SafetyCubit>(),
      child: BlocListener<SafetyCubit, SafetyState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          switch (state) {
            case SafetyReported():
              messenger.showSnackBar(
                const SnackBar(content: Text('Şikayetin alındı. Teşekkürler.')),
              );
            case SafetyBlocked():
              messenger.showSnackBar(
                SnackBar(content: Text('$targetName engellendi.')),
              );
              onBlocked();
            case SafetyFailed(:final message):
              messenger.showSnackBar(SnackBar(content: Text(message)));
            default:
              break;
          }
        },
        child: Builder(
          builder: (context) => PopupMenuButton<String>(
            tooltip: 'Şikayet / engelle',
            child: trigger ?? const ChromeChip(icon: Icons.more_horiz),
            onSelected: (value) {
              if (value == 'report') _openReportSheet(context);
              if (value == 'block') _confirmBlock(context);
            },
            itemBuilder: (context) {
              final colors = context.colors;
              return [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 19, color: colors.plum),
                      const SizedBox(width: 12),
                      const Text('Şikayet et'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, size: 19, color: colors.rose),
                      const SizedBox(width: 12),
                      Text('Engelle', style: TextStyle(color: colors.rose)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openReportSheet(BuildContext context) async {
    final cubit = context.read<SafetyCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(
        targetName: targetName,
        onSubmit: (reason, details) => cubit.report(
          targetUserId: targetUserId,
          reason: reason,
          details: details,
        ),
      ),
    );
  }

  Future<void> _confirmBlock(BuildContext context) async {
    final cubit = context.read<SafetyCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$targetName engellensin mi?'),
        content: const Text(
          'Engellediğin kişi bir daha karşına çıkmaz ve seninle sohbet edemez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.block(targetUserId);
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.targetName, required this.onSubmit});
  final String targetName;
  final void Function(ReportReason reason, String? details) onSubmit;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
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
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.roseSoft,
                  ),
                  child: Icon(Icons.flag_rounded, color: colors.rose, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.targetName} için şikayet',
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      color: colors.plumStrong,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Şikayetin gizli kalır; kişi bunu bilmez.',
              style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
            ),
            const SizedBox(height: 14),
            ...ReportReason.values.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _reason = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _reason == r ? colors.plumTint : colors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _reason == r ? colors.plum : colors.line,
                        width: _reason == r ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(r.label, style: textTheme.bodyLarge),
                        ),
                        if (_reason == r)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: colors.plum,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'EK NOT (OPSİYONEL)',
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: 'Şikayet et',
              onPressed: _reason == null
                  ? null
                  : () {
                      final note = _detailsController.text.trim();
                      widget.onSubmit(_reason!, note.isEmpty ? null : note);
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}
