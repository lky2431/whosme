import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_flutter/game/paper_motion.dart';

void main() {
  Widget scene({String question = 'one', bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: PaperEntrance(
        key: ValueKey(question),
        child: Text('Question $question'),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(
          of: find.byType(PaperEntrance),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('room updates preserve entrance; new questions replay it', (
    tester,
  ) async {
    await tester.pumpWidget(scene());
    expect(opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);

    await tester.pumpWidget(scene());
    expect(opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(scene(question: 'two'));
    expect(find.text('Question one'), findsNothing);
    expect(opacity(tester), 0);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });

  testWidgets(
    'reduced motion shows content immediately, including mid-flight',
    (
      tester,
    ) async {
      await tester.pumpWidget(scene());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(scene(reduced: true));
      expect(find.text('Question one'), findsOneWidget);
      expect(find.byType(Opacity), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(scene(question: 'two', reduced: true));
      expect(find.text('Question two'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
