import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/usecases/watch_answered_today.dart';

/// Drives the dot on the "Günün Sorusu" tab: `true` while today's question
/// is still waiting for this user's answer. It lives as long as the tab
/// bar, so the dot is right from any tab, and stays `false` until the
/// answer is known - no dot is better than a wrong one.
class FeedBadgeCubit extends Cubit<bool> {
  FeedBadgeCubit({required WatchAnsweredToday watchAnsweredToday})
    : _watchAnsweredToday = watchAnsweredToday,
      super(false);

  final WatchAnsweredToday _watchAnsweredToday;
  StreamSubscription<Result<bool>>? _subscription;

  void start() {
    _subscription ??= _watchAnsweredToday().listen((result) {
      if (isClosed) return;
      if (result case Ok<bool>(value: final answered)) emit(!answered);
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
