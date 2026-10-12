import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/main.dart';
import 'game_screen_test.dart' show fixture;

void main() {
  testWidgets('chat, answer sheet and selectable full review', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader(
        'Nunito',
      )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final room = fixture('questions');
    room['players'][1]['done'] = true;
    room['players'][2]['done'] = true;
    room['questionFeed'] = [
      {
        ...room['question'] as Json,
        'index': room['index'],
        'myAnswer': null,
        'submissions': [
          {'playerId': room['players'][1]['id'], 'answer': 'Red'},
          {'playerId': room['players'][2]['id'], 'answer': 'Green'},
        ],
      },
    ];
    final game = GameController(Client('http://localhost:18080/'))
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

    expect(find.text('Answer locked in'), findsNothing);
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Keeping it a mystery'), findsNothing);
    expect(find.text('Blue'), findsNothing);
    await capture('playful-chat');
    await tester.tap(find.text('Your turn!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    await capture('playful-answer');
    await tester.tap(find.text('Back to chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your turn!'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(TextButton, 'Blue'),
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to chat'));
    await tester.pumpAndSettle();
    final reveal = fixture('reveal');
    reveal['results'][0]['playerId'] = 'p0';
    reveal['answerReview'] = [
      {
        'playerId': 'p0',
        'name': 'Alice',
        'actedAs': 'Eva',
        'answers': [
          {'number': 1, 'prompt': 'Favorite color?', 'answer': 'Blue'},
        ],
      },
      {
        'playerId': 'p1',
        'name': 'Ben',
        'actedAs': 'Alice',
        'answers': [
          {'number': 1, 'prompt': 'Favorite color?', 'answer': 'Green'},
        ],
      },
    ];
    game.room = reveal;
    // Notify through the same observable controller used by room updates.
    game.notifyListeners();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Ben'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ben'));
    await tester.pumpAndSettle();
    expect(find.text('Ben was playing Alice'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    await capture('playful-review');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
