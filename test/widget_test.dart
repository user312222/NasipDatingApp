import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/main.dart';

void main() {
  setUp(() async {
    await initDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('App boots and shows the invite gate screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BiNasipApp());
    await tester.pumpAndSettle();

    expect(find.text('Bi Nasip’e hoş geldin.'), findsOneWidget);
    expect(find.text('Devam et'), findsOneWidget);
  });
}
