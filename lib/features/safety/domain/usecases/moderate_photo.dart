import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/safety_repository.dart';

class ModeratePhotoParams extends Equatable {
  const ModeratePhotoParams({required this.fileName, required this.bytes});
  final String fileName;
  final Uint8List bytes;

  @override
  List<Object?> get props => [fileName, bytes.length];
}

class ModeratePhoto implements UseCase<void, ModeratePhotoParams> {
  const ModeratePhoto(this._repository);
  final SafetyRepository _repository;

  @override
  Future<Result<void>> call(ModeratePhotoParams params) =>
      _repository.moderatePhoto(fileName: params.fileName, bytes: params.bytes);
}
