import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class ValueNotifierMock<T> extends Mock implements ValueNotifier<T> {
  @override
  void addListener(VoidCallback? listener) {
    super.noSuchMethod(
      Invocation.method(#addListener, [listener]),
    );
  }
}

void main() {
  group('valueListenableProvider', () {
    testWidgets('rebuilds when value change', (tester) async {
      final listenable = ValueNotifier(0);

      final child = Builder(
          builder: (context) => Text(Provider.of<int>(context).toString(),
              textDirection: TextDirection.ltr));

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: listenable,
          child: child,
        ),
      );

      expect(find.text('0'), findsOneWidget);
      listenable.value++;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets("don't rebuild dependents by default", (tester) async {
      var buildCount = 0;
      final listenable = ValueNotifier(0);
      final child = Builder(builder: (context) {
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: listenable,
          child: child,
        ),
      );

      expect(buildCount, 1);

      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: listenable,
          child: child,
        ),
      );

      expect(buildCount, 1);
    });

    testWidgets('pass keys', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        ValueListenableProvider.value(
          key: key,
          value: ValueNotifier(42),
          child: Container(),
        ),
      );

      expect(key.currentWidget, isInstanceOf<ValueListenableProvider<int>>());
    });

    testWidgets("don't listen again if Value instance doesn't change",
        (tester) async {
      final valueNotifier = ValueNotifierMock<int>();
      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: valueNotifier,
          child: TextOf<int>(),
        ),
      );
      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: valueNotifier,
          child: TextOf<int>(),
        ),
      );

      verify(valueNotifier.addListener(any)).called(1);
      verify(valueNotifier.value);
      verifyNoMoreInteractions(valueNotifier);
    });

    testWidgets('pass updateShouldNotify', (tester) async {
      final shouldNotify = UpdateShouldNotifyMock<int>();
      when(shouldNotify(0, 1)).thenReturn(true);

      final notifier = ValueNotifier(0);
      await tester.pumpWidget(
        ValueListenableProvider.value(
          value: notifier,
          updateShouldNotify: shouldNotify,
          child: TextOf<int>(),
        ),
      );

      verifyZeroInteractions(shouldNotify);

      notifier.value++;
      await tester.pump();

      verify(shouldNotify(0, 1)).called(1);
      verifyNoMoreInteractions(shouldNotify);
    });
  });
}