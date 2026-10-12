import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/main.dart';

Json fixture(String phase) => {
  'code': 'ABC234',
  'phase': phase,
  'version': 1,
  'round': 1,
  'selfId': 'p0',
  'hostId': 'p0',
  'count': 10,
  'index': 0,
  'categories': ['Everyday'],
  'assignedName': 'Ben',
  'players': [
    for (var i = 0; i < 5; i++)
      {
        'id': 'p$i',
        'name': ['Alice', 'Ben', 'Chloe', 'Dev', 'Eva'][i],
        'done': false,
      },
  ],
  'question': {
    'prompt': 'What is your favorite color?',
    'category': 'Everyday',
    'choices': ['Red', 'Blue', 'Green', 'Yellow'],
  },
  'myAnswer': null,
  'answeredCount': 0,
  'myGuess': null,
  'guessedCount': 0,
  'clues': [
    {'prompt': 'What is your favorite color?', 'answer': 'Blue'},
  ],
  'answerReview': [
    for (var i = 0; i < 5; i++)
      {
        'playerId': 'p$i',
        'name': ['Alice', 'Ben', 'Chloe', 'Dev', 'Eva'][i],
        if (phase == 'reveal') 'actedAs': 'Ben',
        'answers': [
          {'number': 1, 'prompt': 'Favorite color?', 'answer': 'Blue'},
        ],
      },
  ],
  'results': [
    {
      'playerId': 'p0',
      'name': 'Alice',
      'actual': 'Ben',
      'guessed': 'Ben',
      'actedAs': 'Eva',
      'correct': true,
    },
  ],
};

void main() {
  for (final count in [3, 4]) {
    testWidgets('host can start only from four players: $count present', (
      tester,
    ) async {
      final room = fixture('lobby');
      room['players'] = (room['players'] as List).take(count).toList();
      final controller = GameController(Client('http://localhost:18080/'))
        ..loading = false
        ..connected = true
        ..room = room;
      await tester.pumpWidget(YournameApp(controller: controller));
      await tester.pumpAndSettle();
      final start = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Deal the names'),
      );
      expect(start.onPressed, count == 4 ? isNotNull : isNull);
      if (count == 3) {
        expect(find.text('1 more friend to get started.'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets('join fields and action remain reachable above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = GameController(Client('http://localhost:18080/'))
      ..loading = false;
    await tester.pumpWidget(YournameApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Join a room'));
    await tester.tap(find.text('Join a room'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alice');
    await tester.enterText(find.byType(TextFormField).last, 'ABC234');
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    final join = find.widgetWithText(FilledButton, 'Join the party');
    await tester.ensureVisible(join);
    await tester.pumpAndSettle();
    expect(tester.getRect(join).bottom, lessThanOrEqualTo(318));
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'ABC234',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Alice',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
    'answer selection survives changing between columns and phone layout',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(Client('http://localhost:18080/'))
        ..loading = false
        ..connected = true
        ..room = fixture('questions');
      await tester.pumpWidget(YournameApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Your turn!'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Blue'));
      await tester.tap(find.text('Blue'));
      for (final size in [const Size(1440, 900), const Size(320, 568)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Lock in my answer'),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          find.descendant(
            of: find.widgetWithText(TextButton, 'Blue'),
            matching: find.byIcon(Icons.check_circle_outline),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(1440, 900),
    const Size(1920, 1080),
  ]) {
    for (final textScale in [1.0, 2.0]) {
      for (final phase in [
        'home',
        'lobby',
        'questions',
        'guessing',
        'reveal',
      ]) {
        testWidgets('$phase fits $size at ${textScale}x text', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = GameController(Client('http://localhost:18080/'))
            ..loading = false
            ..connected = true
            ..categories = {
              'Everyday': 10,
              'Food & drink': 10,
              'Personality': 10,
              'Would you rather': 10,
            }
            ..room = phase == 'home' ? null : fixture(phase);
          await tester.pumpWidget(YournameApp(controller: controller));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (phase == 'questions') {
            await tester.tap(find.text('Your turn!'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Blue'));
            await tester.tap(find.text('Blue'));
            await tester.pump();
            expect(
              tester
                  .widget<FilledButton>(
                    find.widgetWithText(FilledButton, 'Lock in my answer'),
                  )
                  .onPressed,
              isNotNull,
            );
          }
          if (phase != 'home' &&
              find.byType(ExpansionTile).evaluate().isNotEmpty) {
            await tester.ensureVisible(find.byType(ExpansionTile));
            await tester.tap(find.text('The group · 5'));
            await tester.pumpAndSettle();
            expect(find.text('Alice (you)'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  }
}
