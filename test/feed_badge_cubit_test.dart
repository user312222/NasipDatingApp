import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/feed/domain/usecases/watch_answered_today.dart';
import 'package:binasip/features/feed/presentation/bloc/feed_badge_cubit.dart';

import 'support/fakes.dart';

void main() {
  late FakeFeedRepository repo;
  late FeedBadgeCubit cubit;

  setUp(() {
    repo = FakeFeedRepository();
    cubit = FeedBadgeCubit(watchAnsweredToday: WatchAnsweredToday(repo));
  });

  test('shows no dot until the answer is known', () async {
    cubit.start();
    await pumpEventQueue();

    expect(cubit.state, isFalse);
  });

  test('shows the dot while today has no answer', () async {
    cubit.start();
    repo.answered.add(const Ok(false));
    await pumpEventQueue();

    expect(cubit.state, isTrue);
  });

  test('answering clears it; deleting the answer brings it back', () async {
    cubit.start();
    repo.answered.add(const Ok(false));
    await pumpEventQueue();

    repo.answered.add(const Ok(true));
    await pumpEventQueue();
    expect(cubit.state, isFalse);

    repo.answered.add(const Ok(false));
    await pumpEventQueue();
    expect(cubit.state, isTrue);
  });

  test('a failed read leaves the dot as it was', () async {
    cubit.start();
    repo.answered.add(const Err(ServerFailure('Cevap durumu okunamadı.')));
    await pumpEventQueue();

    expect(cubit.state, isFalse);
  });

  test('starting twice keeps a single listener', () async {
    cubit.start();
    cubit.start();
    repo.answered.add(const Ok(false));
    await pumpEventQueue();

    expect(cubit.state, isTrue);
  });

  test('closing cancels the listener and drops a late event', () async {
    cubit.start();
    expect(repo.answered.hasListener, isTrue);

    repo.answered.add(const Ok(false));
    await cubit.close();
    await pumpEventQueue();

    expect(repo.answered.hasListener, isFalse);
    expect(cubit.isClosed, isTrue);
  });
}
