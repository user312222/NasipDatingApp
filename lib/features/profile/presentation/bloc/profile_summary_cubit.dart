import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile.dart';

/// The profile behind the "Profilin" card on the Hesap tab. Stays null
/// until it is read - and when it cannot be read or does not exist: the
/// card then simply has no summary to show. Reporting a failed read is the
/// edit screen's job, which is one tap away.
class ProfileSummaryCubit extends Cubit<Profile?> {
  ProfileSummaryCubit({required GetProfile getProfile})
    : _getProfile = getProfile,
      super(null);

  final GetProfile _getProfile;

  /// Also called again when the edit screen closes, to pick up a save.
  Future<void> load(String userId) async {
    final result = await _getProfile(GetProfileParams(userId));
    if (isClosed) return;
    if (result case Ok<Profile?>(value: final profile?)) emit(profile);
  }
}
