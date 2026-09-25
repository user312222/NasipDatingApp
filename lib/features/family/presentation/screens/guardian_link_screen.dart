import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/relationship.dart';
import '../bloc/guardian_cubit.dart';

/// FR-8.2/8.3: the guardian's whole "profile" — a name, how they're
/// related, and the invite code that links them to a single account.
class GuardianLinkScreen extends StatefulWidget {
  const GuardianLinkScreen({super.key});

  @override
  State<GuardianLinkScreen> createState() => _GuardianLinkScreenState();
}

class _GuardianLinkScreenState extends State<GuardianLinkScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  Relationship? _relationship;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _relationship == null ||
        _codeController.text.trim().isEmpty) {
      setState(() => _error = 'Ad, yakınlık derecesi ve aile kodu zorunlu.');
      return;
    }
    setState(() => _error = null);
    final userId =
        context.read<AuthCubit>().currentUser?.id ?? 'unknown_guardian';
    context.read<GuardianCubit>().link(
      guardianUserId: userId,
      guardianName: _nameController.text.trim(),
      relationship: _relationship!,
      inviteCode: _codeController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: BlocConsumer<GuardianCubit, GuardianState>(
        listener: (context, state) {
          if (state is GuardianLinked) context.go('/guardian/home');
          if (state is GuardianLinkFailed) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLinking = state is GuardianLinking;
          return WizardBackdrop(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WizardHeader(
                      icon: Icons.link_rounded,
                      title: 'Yakınının hesabına bağlan.',
                      subtitle:
                          'Yakının, kendi Bi Nasip hesabından sana bir aile kodu verecek. '
                          'Kod olmadan hiçbir bilgiye erişemezsin.',
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'ADIN'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'YAKINLIK DERECEN',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Relationship.values.map((r) {
                        final selected = _relationship == r;
                        return ChoiceChip(
                          label: Text(r.label),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: colors.plumFill,
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: selected ? colors.plum : colors.line,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelStyle: textTheme.bodyMedium?.copyWith(
                            color: selected ? Colors.white : colors.plumStrong,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _relationship = r),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'AİLE KODU'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.rose,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'Bağlan',
                      loading: isLinking,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
