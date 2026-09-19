import '../../../../core/error/exceptions.dart';
import '../models/waitlist_entry_model.dart';

/// **Placeholder data source.** Holds entries in memory for the duration
/// of the app session so the feature is runnable end-to-end before a
/// backend exists. Swap for a `WaitlistRemoteDataSource` backed by
/// Firestore when FR-1/FR-7 land — `WaitlistRepositoryImpl` and everything
/// above it stays unchanged, since both implement the same interface.
abstract interface class WaitlistLocalDataSource {
  Future<void> submit(WaitlistEntryModel entry);
}

class WaitlistLocalDataSourceImpl implements WaitlistLocalDataSource {
  final List<WaitlistEntryModel> _entries = [];

  @override
  Future<void> submit(WaitlistEntryModel entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (entry.name.trim().isEmpty || entry.contact.trim().isEmpty) {
      throw const ServerException('Ad ve e-posta/telefon zorunludur.');
    }
    _entries.add(entry);
  }
}
