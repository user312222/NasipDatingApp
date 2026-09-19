import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../bloc/waitlist_cubit.dart';

class WaitlistScreen extends StatelessWidget {
  const WaitlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WaitlistCubit>(),
      child: const _WaitlistView(),
    );
  }
}

class _WaitlistView extends StatefulWidget {
  const _WaitlistView();

  @override
  State<_WaitlistView> createState() => _WaitlistViewState();
}

class _WaitlistViewState extends State<_WaitlistView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: BlocConsumer<WaitlistCubit, WaitlistState>(
        listener: (context, state) {
          if (state is WaitlistFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'TÜRKİYE’DE YAKINDA — DAVETİYELİ ERKEN ERİŞİM',
                    style: textTheme.labelSmall?.copyWith(color: colors.brass),
                  ),
                  const SizedBox(height: 12),
                  Text('Herkesin bi nasibi var.', style: textTheme.displayLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Evliliği hedefleyen, mahremiyetini kendi elinde tutmak isteyen medeni '
                    'Müslüman bekârlar için tasarlanan yeni bir tanışma deneyimi.',
                    style: textTheme.bodyLarge?.copyWith(color: colors.inkSoft),
                  ),
                  const SizedBox(height: 32),
                  if (state is WaitlistSuccess)
                    _SuccessCard(name: state.name)
                  else
                    _WaitlistForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      contactController: _contactController,
                      cityController: _cityController,
                      isSubmitting: state is WaitlistSubmitting,
                      onSubmit: () {
                        if (_formKey.currentState?.validate() != true) return;
                        context.read<WaitlistCubit>().submit(
                          name: _nameController.text.trim(),
                          contact: _contactController.text.trim(),
                          city: _cityController.text.trim().isEmpty
                              ? null
                              : _cityController.text.trim(),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaitlistForm extends StatelessWidget {
  const _WaitlistForm({
    required this.formKey,
    required this.nameController,
    required this.contactController,
    required this.cityController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController cityController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bekleme listesine katıl', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'İlk 500 kişiye ömür boyu üyelik ayrıcalığı tanınacak.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'AD'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Adını gir' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'E-POSTA VEYA TELEFON'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'ŞEHİR (OPSİYONEL)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Bana da nasip olsun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, color: colors.brass, size: 28),
            const SizedBox(height: 12),
            Text('Teşekkürler, $name.', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Erken erişim daveti hazır olduğunda sana haber vereceğiz.',
              style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
