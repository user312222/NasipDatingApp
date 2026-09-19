/// Thrown by data sources (remote or local). Repositories catch these and
/// translate them into a [Failure] — nothing above the repository layer
/// should ever catch or reference an [Exception] type directly.
class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;
}

class CacheException implements Exception {
  const CacheException([this.message]);
  final String? message;
}
