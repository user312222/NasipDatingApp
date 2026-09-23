import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../bloc/profile_cubit.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _religiousNoteController = TextEditingController();
  final _madhhabController = TextEditingController();
  DateTime? _birthDate;
  String? _error;

  /// KVKK m.6: din bilgisi özel nitelikli veridir ve ayrı bir açık rıza
  /// gerektirir — [religiousPracticeNote]/[madhhab]'ı boş bırakmak bu
  /// rızaya hiç ihtiyaç duymaz, ama biri doldurulursa (ve "Belirtmek
  /// istemiyorum" gibi aslında hiçbir şey açıklamayan bir seçim değilse)
  /// devam etmeden önce bu kutunun işaretlenmesi şart.
  bool _sensitiveDataConsent = false;

  static const _madhhabSuggestions = [
    'Sünni',
    'Caferi',
    'Alevi',
    'Belirtmek istemiyorum',
  ];

  bool get _hasSensitiveData =>
      _religiousNoteController.text.trim().isNotEmpty ||
      (_madhhabController.text.trim().isNotEmpty &&
          _madhhabController.text.trim() != 'Belirtmek istemiyorum');

  @override
  void initState() {
    super.initState();
    // Rıza kutusunun görünürlüğü/gerekliliği yazarken anlık güncellensin.
    _religiousNoteController.addListener(_onSensitiveFieldChanged);
    _madhhabController.addListener(_onSensitiveFieldChanged);
  }

  void _onSensitiveFieldChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    _religiousNoteController.dispose();
    _madhhabController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _continue() {
    if (_nameController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _birthDate == null) {
      setState(() => _error = 'Ad, doğum tarihi ve şehir zorunlu.');
      return;
    }
    if (_hasSensitiveData && !_sensitiveDataConsent) {
      setState(
        () => _error =
            'Dini pratik/mezhep bilgini paylaşmak için aşağıdaki onayı '
            'işaretlemelisin — ya da bu alanları boş bırakabilirsin.',
      );
      return;
    }
    context.read<ProfileCubit>().updateDetails(
      name: _nameController.text,
      birthDate: _birthDate!,
      city: _cityController.text,
      educationLevel: _educationController.text.trim().isEmpty
          ? null
          : _educationController.text.trim(),
      occupation: _occupationController.text.trim().isEmpty
          ? null
          : _occupationController.text.trim(),
      religiousPracticeNote: _religiousNoteController.text.trim().isEmpty
          ? null
          : _religiousNoteController.text.trim(),
      madhhab: _madhhabController.text.trim().isEmpty
          ? null
          : _madhhabController.text.trim(),
    );
    context.push('/profile/family');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seni Tanıyalım')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'AD'),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'DOĞUM TARİHİ'),
                  child: Text(
                    _birthDate == null
                        ? 'Seç'
                        : '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'ŞEHİR'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'EĞİTİM (OPSİYONEL)',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: 'MESLEK (OPSİYONEL)',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _religiousNoteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'DİNİ PRATİĞİN (OPSİYONEL)',
                  hintText: 'Kendi cümlelerinle, istersen boş bırak',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _madhhabController,
                decoration: const InputDecoration(
                  labelText: 'MEZHEP (OPSİYONEL)',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _madhhabSuggestions
                    .map(
                      (m) => ActionChip(
                        label: Text(m),
                        onPressed: () =>
                            setState(() => _madhhabController.text = m),
                        backgroundColor: colors.plumTint,
                        labelStyle: textTheme.bodyMedium?.copyWith(
                          color: colors.plumStrong,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              if (_hasSensitiveData) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.plumTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Din/mezhep bilgisi, KVKK’ya göre özel nitelikli '
                        'veridir ve ayrı bir açık rıza gerektirir.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.plumStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => setState(
                          () => _sensitiveDataConsent = !_sensitiveDataConsent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _sensitiveDataConsent,
                              onChanged: (v) => setState(
                                () => _sensitiveDataConsent = v ?? false,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Yukarıda yazdığım dini pratik/mezhep '
                                  'bilgisinin işlenmesini açıkça kabul '
                                  'ediyorum.',
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.rose),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
