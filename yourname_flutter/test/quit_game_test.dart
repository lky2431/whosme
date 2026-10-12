import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/game/game_router.dart';
import 'package:yourname_flutter/main.dart';
import 'game_screen_test.dart' show fixture;

class QuitController extends GameController {
  QuitController() : super(Client('http://localhost:18080/'));
  final actions = <String>[];
  @override
  Future<void> act(String action, [Json payload = const {}]) async {
    actions.add(action);
    room = null;
    notifyListeners();
  }
}

void main() {
  testWidgets('room links prefill once without keeping the code in home URL', (
    tester,
  ) async {
    final game = QuitController()..loading = false;
    await tester.pumpWidget(YournameApp(controller: game));
    await tester.pumpAndSettle();
    final router =
        Router.of(tester.element(find.byType(Scaffold))).routerDelegate
            as GameRouter;
    await router.setNewRoutePath('/join/ABC234');
    await tester.pumpAndSettle();
    expect(router.currentConfiguration, '/');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'ABC234',
    );
    await router.setNewRoutePath(router.currentConfiguration);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextFormField).last, 'XYZ789');
    game.room = fixture('lobby');
    game.notifyListeners();
    await tester.pumpAndSettle();
    await game.act('leave');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pumpAndSettle();
  });
  testWidgets('remote quit dismisses the group sheet and shows lobby', (
    tester,
  ) async {
    final game = QuitController()
      ..loading = false
      ..connected = true
      ..room = fixture('questions');
    await tester.pumpWidget(YournameApp(controller: game));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('See the group'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    game.room = fixture('lobby')..['roundEndedBy'] = 'Ben';
    game.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.textContaining('Ben left. The round has ended.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pumpAndSettle();
  });
  for (final phase in ['lobby', 'questions', 'guessing', 'reveal']) {
    testWidgets('$phase quit requires confirmation and returns home', (
      tester,
    ) async {
      final game = QuitController()
        ..loading = false
        ..connected = true
        ..room = fixture(phase);
      await tester.pumpWidget(YournameApp(controller: game));
      await tester.pumpAndSettle();
      final active = phase == 'questions' || phase == 'guessing';
      await tester.tap(
        active && phase == 'questions'
            ? find.byTooltip('Quit game')
            : find.text(active ? 'Quit game' : 'Leave room'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(active ? 'Quit this game?' : 'Leave this room?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'You are the host. Leaving will close this room for everyone and return all players to the home screen.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(game.actions, isEmpty);
      await tester.tap(
        active && phase == 'questions'
            ? find.byTooltip('Quit game')
            : find.text(active ? 'Quit game' : 'Leave room'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(active ? 'Quit game' : 'Leave room'),
        ),
      );
      await tester.pumpAndSettle();
      expect(game.actions, ['leave']);
      expect(game.room, isNull);
      final router =
          Router.of(tester.element(find.byType(Scaffold))).routerDelegate
              as GameRouter;
      expect(router.currentConfiguration, '/');
      await tester.pumpWidget(const SizedBox());
      game.dispose();
      await tester.pumpAndSettle();
    });
  }

  testWidgets('routes track server phase; back asks before quitting', (
    tester,
  ) async {
    final game = QuitController()
      ..loading = false
      ..connected = true
      ..room = fixture('guessing');
    await tester.pumpWidget(YournameApp(controller: game));
    await tester.pumpAndSettle();
    final router =
        Router.of(tester.element(find.byType(Scaffold))).routerDelegate
            as GameRouter;
    expect(router.currentConfiguration, '/room/ABC234/guessing');
    final back = router.setNewRoutePath('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    await back;
    expect(router.currentConfiguration, '/room/ABC234/guessing');
    expect(game.actions, isEmpty);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pumpAndSettle();
  });
}
