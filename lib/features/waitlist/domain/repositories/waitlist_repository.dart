import '../../../../core/result/result.dart';
import '../entities/waitlist_entry.dart';

/// Domain-layer contract. The presentation layer and use cases depend on
/// this interface, never on [WaitlistRepositoryImpl] or any concrete data
/// source — that's what lets the data layer swap from an in-memory stub to
/// Firestore later without touching a single Bloc or use case.
abstract interface class WaitlistRepository {
  Future<Result<void>> submit(WaitlistEntry entry);
}
