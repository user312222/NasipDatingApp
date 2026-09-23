/// **Placeholder data source.** The real one triggers a server-side
/// cascading delete. In this mock, "erasing everything" is done by the
/// app resetting all in-memory mock stores right after (see
/// `core/restart/restart_app.dart`), so this only records the request.
abstract interface class AccountRemoteDataSource {
  Future<void> deleteAccount(String userId);
}

class MockAccountRemoteDataSource implements AccountRemoteDataSource {
  final Set<String> deletedUserIds = {};

  @override
  Future<void> deleteAccount(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    deletedUserIds.add(userId);
  }
}
