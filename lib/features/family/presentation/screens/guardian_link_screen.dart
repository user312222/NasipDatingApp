import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/guardian_link.dart';
import '../../domain/entities/relationship.dart';
import '../bloc/current_link_cubit.dart';
import '../bloc/guardian_cubit.dart';

/// FR-8.2/8.3: the guardian's whole "profile" — a name, how they're
/// related, and the invite code that links them to a single account.
///
/// It is the last step of a guardian's registration, and also how a
/// guardian who is already linked moves to another account (a wrong code,
/// another relative): a guardian follows one account at a time, so a new
/// link replaces the old one. In that case the screen says whose account
/// is linked now and asks before replacing it - however it was opened.
class GuardianLinkScreen extends StatelessWidget {
  const GuardianLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        context.read<AuthCubit>().currentUser?.id ?? 'unknown_guardian';

    return BlocProvider(
      create: (_) => sl<CurrentLinkCubit>()..load(userId),
      child: BlocBuilder<CurrentLinkCubit, CurrentLinkState>(
        builder: (context, current) => switch (current) {
          CurrentLinkLoading() => Scaffold(
            appBar: AppBar(),
            body: const WizardBackdrop(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          CurrentLinkNone() => _LinkForm(userId: userId),
          CurrentLinkFound(:final link) => _LinkForm(
            userId: userId,
            current: link,
          ),
        },
      ),
    );
  }
}

class _LinkForm extends StatefulWidget {
  const _LinkForm({required this.userId, this.current});

  final String userId;

  /// The link this one would replace; null for a first link.
  final GuardianLink? current;

  @override
  State<_LinkForm> createState() => _LinkFormState();
}

class _LinkFormState extends State<_LinkForm> {
  late final _nameController = TextEditingController(
    text: widget.current?.guardianName,
  );
  final _codeController = TextEditingController();
  late Relationship? _relationship = widget.current?.relationship;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _relationship == null ||
        _codeController.text.trim().isEmpty) {
      setState(() => _error = 'Ad, yakınlık derecesi ve aile kodu zorunlu.');
      return;
    }
    setState(() => _error = null);

    final current = widget.current;
    if (current != null && !await _confirmReplacing(current)) return;
    if (!mounted) return;

    context.read<GuardianCubit>().link(
      guardianUserId: widget.userId,
      guardianName: _nameController.text.trim(),
      relationship: _relationship!,
      inviteCode: _codeController.text.trim(),
    );
  }

  Future<bool> _confirmReplacing(GuardianLink current) async {
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bağlantı değişsin mi?'),
        content: Text(
          '${current.singleName ?? 'Şimdiki hesap'} ile bağlantın kalkar ve '
          'paylaştığı eşleşmeleri artık göremezsin. Yeniden bağlanmak için '
          'ondan tekrar aile kodu alman gerekir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
    return replace ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final current = widget.current;

    return Scaffold(
      appBar: AppBar(
        // Opened by address there is no page underneath and so no back
        // arrow; a linked guardian still has a home to go back to.
        leading: current != null && !context.canPop()
            ? BackButton(onPressed: () => context.go('/guardian/home'))
            : null,
      ),
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
                    if (current == null)
                      const WizardHeader(
                        icon: Icons.link_rounded,
                        title: 'Yakınının hesabına bağlan.',
                        subtitle:
                            'Yakının, kendi Bi Nasip hesabından sana bir aile kodu verecek. '
                            'Kod olmadan hiçbir bilgiye erişemezsin.',
                      )
                    else ...[
                      const WizardHeader(
                        icon: Icons.sync_alt_rounded,
                        title: 'Bağlı hesabı değiştir.',
                        subtitle:
                            'Aynı anda yalnızca bir hesaba bağlı olabilirsin. Yeni bir '
                            'aile kodu girdiğinde şimdiki bağlantın kalkar.',
                      ),
                      const SizedBox(height: 20),
                      SectionCard(
                        icon: Icons.person_pin_rounded,
                        title: 'Şu an bağlı olduğun hesap',
                        body: current.singleName ?? 'Adı okunamadı',
                      ),
                    ],
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
                      decoration: InputDecoration(
                        labelText: current == null
                            ? 'AİLE KODU'
                            : 'YENİ AİLE KODU',
                      ),
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
                      label: current == null ? 'Bağlan' : 'Bağlantıyı değiştir',
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
