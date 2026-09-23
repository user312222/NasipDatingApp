import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/result/result.dart';
import '../../../../theme/app_colors.dart';
import '../../../safety/domain/usecases/moderate_photo.dart';
import '../bloc/profile_cubit.dart';

class ProfilePhotosScreen extends StatefulWidget {
  const ProfilePhotosScreen({super.key});

  @override
  State<ProfilePhotosScreen> createState() => _ProfilePhotosScreenState();
}

class _ProfilePhotosScreenState extends State<ProfilePhotosScreen> {
  final _picker = ImagePicker();
  List<Uint8List> _photos = const [];
  String? _error;

  Future<void> _pickPhotos() async {
    final picked = await _picker.pickMultiImage(limit: 6);
    if (picked.isEmpty) return;
    // FR-6.3: every photo goes through moderation before it's accepted.
    final moderate = sl<ModeratePhoto>();
    final accepted = <Uint8List>[];
    final rejections = <String>[];
    for (final file in picked) {
      final bytes = await file.readAsBytes();
      final result = await moderate(
        ModeratePhotoParams(fileName: file.name, bytes: bytes),
      );
      switch (result) {
        case Ok<void>():
          accepted.add(bytes);
        case Err<void>(:final failure):
          rejections.add(failure.message);
      }
    }
    final combined = [..._photos, ...accepted].take(6).toList();
    setState(() {
      _photos = combined;
      _error = rejections.isEmpty ? null : rejections.join('\n');
    });
    if (!mounted) return;
    context.read<ProfileCubit>().updatePhotos(_photos);
  }

  void _removeAt(int index) {
    setState(() => _photos = [..._photos]..removeAt(index));
    context.read<ProfileCubit>().updatePhotos(_photos);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fotoğrafların')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'En az 1, en fazla 6 fotoğraf ekle.',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Fotoğraflarının kime, ne zaman görüneceğini ilerleyen bir adımda sen belirleyeceksin.',
                style: textTheme.bodyMedium?.copyWith(color: colors.inkSoft),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _photos.length < 6 ? _photos.length + 1 : 6,
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return _AddTile(colors: colors, onTap: _pickPhotos);
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            _photos[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeAt(index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: colors.plumStrong,
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.rose),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_photos.isEmpty) {
                    setState(() => _error = 'En az 1 fotoğraf ekle.');
                    return;
                  }
                  context.push('/profile/privacy');
                },
                child: const Text('Devam et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.colors, required this.onTap});
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.plumTint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.line),
        ),
        child: Icon(Icons.add_photo_alternate_outlined, color: colors.plum),
      ),
    );
  }
}
