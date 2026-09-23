import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
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
  });

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
            onSelected: (value) {
              if (value == 'report') _openReportSheet(context);
              if (value == 'block') _confirmBlock(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Şikayet et')),
              PopupMenuItem(value: 'block', child: Text('Engelle')),
            ],
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
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.targetName} için şikayet',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Şikayetin gizli kalır; kişi bunu bilmez.',
              style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
            ),
            const SizedBox(height: 12),
            ...ReportReason.values.map(
              (r) => InkWell(
                onTap: () => setState(() => _reason = r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _reason == r
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _reason == r ? colors.plum : colors.inkSoft,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(r.label, style: textTheme.bodyLarge),
                      ),
                    ],
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reason == null
                  ? null
                  : () {
                      final note = _detailsController.text.trim();
                      widget.onSubmit(_reason!, note.isEmpty ? null : note);
                      Navigator.of(context).pop();
                    },
              child: const Text('Şikayet et'),
            ),
          ],
        ),
      ),
    );
  }
}
