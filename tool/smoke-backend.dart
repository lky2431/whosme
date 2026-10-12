import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:yourname_client/yourname_client.dart';

typedef Json = Map<String, dynamic>;
Json read(String value) => jsonDecode(value) as Json;
void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

// Creates one temporary guest room, exercises HTTP and WebSocket gameplay,
// and closes the room on exit. Does not create accounts or saved game history.
Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Pass the backend URL.');
  final clients = List.generate(4, (_) => Client(args.single));
  final seats = <Json>[];
  StreamSubscription<String>? subscription;
  String? code;
  try {
    final categories = read(await clients.first.game.categories());
    check(
      categories.values.fold<int>(0, (a, b) => a + (b as int)) >= 2,
      'Question seed is missing.',
    );
    try {
      final unexpected = read(
        await clients.first.game.createRoom('Invalid smoke', 1, [
          categories.keys.first,
        ], avatarIndex: 0),
      );
      await clients.first.game.act(
        unexpected['code'],
        unexpected['token'],
        'leave',
        '{}',
      );
      throw StateError('One-question rooms should be rejected.');
    } on GameException {
      stdout.writeln('Minimum of two questions enforced.');
    }
    seats.add(
      read(
        await clients.first.game.createRoom('Deploy smoke 1', 2, [
          categories.keys.first,
        ], avatarIndex: 0),
      ),
    );
    code = seats.first['code'] as String;
    final initial = Completer<void>();
    final guessing = Completer<void>();
    subscription = clients.first.game
        .watch(code, seats.first['token'])
        .listen(
          (event) {
            final view = read(event);
            if (!initial.isCompleted) initial.complete();
            if (view['phase'] == 'guessing' && !guessing.isCompleted) {
              guessing.complete();
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!initial.isCompleted) initial.completeError(error, stack);
            if (!guessing.isCompleted) guessing.completeError(error, stack);
          },
        );
    await initial.future.timeout(const Duration(seconds: 30));
    for (var i = 1; i < clients.length; i++) {
      seats.add(
        read(
          await clients[i].game.joinRoom(
            code,
            'Deploy smoke ${i + 1}',
            avatarIndex: i,
          ),
        ),
      );
    }
    var view = read(
      await clients.first.game.act(code, seats.first['token'], 'start', '{}'),
    );
    check(view['phase'] == 'questions', 'Four-player round did not start.');
    for (var q = 0; q < 2; q++) {
      for (var i = 0; i < clients.length; i++) {
        view = read(
          await clients[i].game.act(
            code,
            seats[i]['token'],
            'answer',
            jsonEncode({'round': view['round'], 'index': q, 'choice': i}),
          ),
        );
      }
    }
    check(view['phase'] == 'guessing', 'Two-question round did not advance.');
    await guessing.future.timeout(const Duration(seconds: 30));
    for (var i = 0; i < clients.length; i++) {
      view = read(
        await clients[i].game.act(
          code,
          seats[i]['token'],
          'guess',
          jsonEncode({
            'round': view['round'],
            'playerId': seats[(i + 1) % clients.length]['view']['selfId'],
          }),
        ),
      );
    }
    check(view['phase'] == 'reveal', 'Round did not reach results.');
    check((view['results'] as List).length == 4, 'Missing player results.');
    stdout.writeln(
      'PASS: seeded questions, four-player round, answers, guesses, results, WebSocket updates.',
    );
  } finally {
    await subscription?.cancel();
    if (code != null && seats.isNotEmpty) {
      await clients.first.game.act(code, seats.first['token'], 'leave', '{}');
      stdout.writeln('Temporary smoke room removed.');
    }
    for (final client in clients) {
      client.close();
    }
  }
}
