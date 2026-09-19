import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../bloc/auth_cubit.dart';

class InviteGateScreen extends StatefulWidget {
  const InviteGateScreen({super.key});

  @override
  State<InviteGateScreen> createState() => _InviteGateScreenState();
}

class _InviteGateScreenState extends State<InviteGateScreen> {
  final _codeController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is InviteAccepted) {
            context.push('/account-type');
          } else if (state is InviteRejected) {
            setState(() => _errorText = 'Bu kod tanınmıyor.');
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isChecking = state is InviteCheckInProgress;
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'DAVETİYELİ ERKEN ERİŞİM',
                          style: textTheme.labelSmall?.copyWith(color: colors.brass),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bi Nasip’e hoş geldin.',
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Şu an kapalı beta aşamasındayız. Devam etmek için davetiye kodunu gir.',
                          style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _codeController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'DAVETİYE KODU',
                                    errorText: _errorText,
                                  ),
                                  onChanged: (_) {
                                    if (_errorText != null) setState(() => _errorText = null);
                                  },
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: isChecking
                                      ? null
                                      : () {
                                          final code = _codeController.text.trim();
                                          if (code.isEmpty) {
                                            setState(() => _errorText = 'Kodu gir');
                                            return;
                                          }
                                          context.read<AuthCubit>().checkInviteCode(code);
                                        },
                                  child: isChecking
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Devam et'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => context.push('/waitlist'),
                          child: Text(
                            'Davetiye kodun yok mu? Bekleme listesine katıl',
                            style: textTheme.bodyMedium?.copyWith(color: colors.plum),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
