import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/main.dart';

class SeatEndpoint implements EndpointGame {
  final events = StreamController<String>();
  @override
  Future<String> categories() async => '{"Everyday":40}';
  @override
  Stream<String> watch(String code, String token) => events.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SeatClient implements Client {
  @override
  final SeatEndpoint game = SeatEndpoint();
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final message in [
    'Room not found or expired. Ask the host for a new code.',
    'Your seat is no longer available. Join a room again.',
  ]) {
    testWidgets('clears saved seat and returns home: $message', (tester) async {
      SharedPreferences.setMockInitialValues({
        'yourname.seat': jsonEncode({'code': 'ABC234', 'token': 'old-seat'}),
      });
      final client = SeatClient();
      final game = GameController(client);
      await game.initialize();
      await tester.pumpWidget(YournameApp(controller: game));
      client.game.events.addError(GameException(message: message));
      await tester.pumpAndSettle();
      expect(game.hasSeat, isFalse);
      expect(game.room, isNull);
      expect(game.error, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString(game.storageKey),
        isNull,
      );
      expect(find.text('Reconnecting to your room…'), findsNothing);
      expect(find.text('Forget seat'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
      unawaited(client.game.events.close());
    });
  }

  test('connection failure preserves saved seat', () async {
    SharedPreferences.setMockInitialValues({
      'yourname.seat': jsonEncode({'code': 'ABC234', 'token': 'valid-seat'}),
    });
    final client = SeatClient();
    final game = GameController(client);
    await game.initialize();
    client.game.events.addError(Exception('offline'));
    await Future<void>.delayed(Duration.zero);
    expect(game.hasSeat, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getString(game.storageKey),
      isNotNull,
    );
    game.dispose();
    unawaited(client.game.events.close());
  });
}

