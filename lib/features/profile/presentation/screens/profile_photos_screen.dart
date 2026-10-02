import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/result/result.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
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
      appBar: AppBar(),
      body: WizardBackdrop(
        child: WizardBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WizardHeader(
                icon: Icons.photo_camera_back_rounded,
                title: 'En az 1, en fazla 6 fotoğraf ekle.',
                subtitle: 'Fotoğraflarının kime, ne zaman görüneceğini ilerleyen bir adımda sen belirleyeceksin.',
                step: 1,
                totalSteps: 5,
              ),
              const SizedBox(height: 20),
              _PhotoGrid(
                tiles: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.memory(_photos[i], fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeAt(i),
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
                    ),
                  if (_photos.length < 6)
                    _AddTile(colors: colors, onTap: _pickPhotos),
                ],
              ),
              const Spacer(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.rose),
                ),
              ],
              const SizedBox(height: 16),
              GradientButton(
                label: 'Devam et',
                onPressed: () {
                  if (_photos.isEmpty) {
                    setState(() => _error = 'En az 1 fotoğraf ekle.');
                    return;
                  }
                  context.push('/profile/privacy');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three square tiles per row, built from plain rows instead of a
/// shrink-wrapped `GridView`: `WizardBody` measures its child's intrinsic
/// height, which a viewport cannot report (it threw and the whole step
/// rendered blank).
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.tiles});

  static const _perRow = 3;
  static const _gap = 10.0;

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += _perRow)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : _gap),
            child: Row(
              children: [
                for (var col = 0; col < _perRow; col++) ...[
                  if (col > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: row + col < tiles.length
                        ? AspectRatio(aspectRatio: 1, child: tiles[row + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
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
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.plumTint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.line),
        ),
        child: Icon(Icons.add_photo_alternate_outlined, color: colors.plum),
      ),
    );
  }
}
