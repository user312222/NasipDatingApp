import 'package:equatable/equatable.dart';

/// Base type for anything that can go wrong in the domain/data layers.
/// Repositories translate data-source [Exception]s into a [Failure] and
/// hand it up to the presentation layer via [Result] — presentation code
/// never sees raw exceptions.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The backend (Firebase/Firestore, REST API, ...) returned an error.
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Sunucuyla iletişimde bir sorun oluştu.',
  ]);
}

/// No network connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'İnternet bağlantısı yok.']);
}

/// Local cache/storage read or write failed.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cihazda veri okunamadı/yazılamadı.']);
}

/// User input failed validation before it ever reached a data source.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Catch-all for anything unexpected; keep this rare — prefer a specific
/// [Failure] subtype so the UI can react meaningfully.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Beklenmeyen bir hata oluştu.']);
}
