import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_flutter/main.dart';
import 'game_screen_test.dart' show fixture;
import 'localization_test.dart' show RecordingGame;

void main() {
  testWidgets('browse, guess, lock and reveal both outcomes', (tester) async {
    tester.view.physicalSize = const Size(900, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    });
    final room = fixture('guessing');
    room['answerReview'] = [
      for (var i = 0; i < 2; i++)
        {
          'playerId': 'p${i + 1}',
          'name': ['Ben', 'Chloe'][i],
          'answers': [
            {
              'number': 1,
              'prompt': 'Favorite color?',
              'answer': ['Blue', 'Green'][i],
            },
          ],
        },
    ];
    final game = RecordingGame()
      ..loading = false
      ..connected = true
      ..room = room;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: YournameApp(controller: game),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../.local/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    expect(find.text('Blue'), findsNothing);
    expect(find.text('I think it was…'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    await capture('guessing-choices');
    await tester.tap(find.byKey(const ValueKey('review-p1')));
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('review-p2')));
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsNothing);
    expect(find.text('Green'), findsOneWidget);
    await tester.tap(find.text('Ben').last);
    await tester.pumpAndSettle();
    await capture('guessing-answers');
    await tester.ensureVisible(find.text('This is my double'));
    await tester.tap(find.text('This is my double'));
    expect(game.sent, {'action': 'guess', 'round': 1, 'playerId': 'p1'});
    room['myGuess'] = 'p1';
    game.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Guess locked in'),
          )
          .onPressed,
      isNull,
    );
    for (final correct in [true, false]) {
      game.room = fixture('reveal');
      game.room!['results'][0]['playerId'] = 'p0';
      game.room!['results'][0]['correct'] = correct;
      game.notifyListeners();
      await tester.pumpAndSettle();
      final message = correct
          ? 'Congratulations! You found your double!'
          : 'Not quite! Your guess was incorrect.';
      await tester.ensureVisible(find.text(message));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      await capture(correct ? 'guess-correct' : 'guess-incorrect');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
