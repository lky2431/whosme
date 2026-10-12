// Run against a disposable/local database only:
// dart run tool/multiplayer_smoke.dart http://127.0.0.1:18080/
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:yourname_client/yourname_client.dart';

typedef Json = Map<String, dynamic>;
void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> rejected(Future<dynamic> Function() fn) async {
  try {
    await fn();
  } on GameException {
    return;
  }
  throw StateError('Expected server to reject invalid action');
}

Future<void> until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for WebSocket updates');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

class Seat {
  Seat(this.client, this.envelope) : view = envelope['view'] as Json;
  Client client;
  final Json envelope;
  Json view;
  StreamSubscription<String>? stream;
  String get code => envelope['code'] as String;
  String get token => envelope['token'] as String;
  String get id => view['selfId'] as String;
  int events = 0;
  void watch() {
    stream = client.game.watch(code, token).listen((raw) {
      final incoming = jsonDecode(raw) as Json;
      if ((incoming['version'] as int) >= (view['version'] as int)) {
        view = incoming;
      }
      events++;
    });
  }

  Future<String> act(String action, [Json data = const {}]) =>
      client.game.act(code, token, action, jsonEncode(data));
}

Future<void> main(List<String> args) async {
  final url = args.isEmpty ? 'http://127.0.0.1:18080/' : args.first;
  final seats = <Seat>[];
  final hostClient = Client(url);
  try {
    final categories = jsonDecode(await hostClient.game.categories()) as Json;
    check(
      categories.length == 4 && categories.values.every((n) => n == 10),
      'Expected 40 categorized database questions',
    );
    check(
      await hostClient.game.categories() == jsonEncode(categories),
      'Seed must be idempotent',
    );
    final host = Seat(
      hostClient,
      jsonDecode(
            await hostClient.game.createRoom('Alice', 10, [
              'Everyday',
              'Personality',
            ], avatarIndex: 0),
          )
          as Json,
    );
    seats.add(host);
    host.watch();
    await rejected(() => host.act('start'));
    await rejected(
      () => hostClient.game.joinRoom(host.code, ' ALICE ', avatarIndex: 0),
    );
    await rejected(
      () => hostClient.game.snapshot(host.code, 'invalid-seat-secret'),
    );
    final joined = await Future.wait(
      ['Ben', 'Chloe', 'Dev'].map((name) async {
        final client = Client(url);
        return Seat(
          client,
          jsonDecode(
                await client.game.joinRoom(host.code, name, avatarIndex: 1),
              )
              as Json,
        );
      }),
    );
    seats.addAll(joined);
    for (final seat in joined) {
      seat.watch();
    }
    await until(
      () => seats.every(
        (s) =>
            (s.view['players'] as List).length == seats.length && s.events > 0,
      ),
    );
    await rejected(() => seats[1].act('start'));
    await host.act('start');
    await until(() => seats.every((s) => s.view['phase'] == 'questions'));
    await rejected(
      () => hostClient.game.joinRoom(host.code, 'Late arrival', avatarIndex: 2),
    );
    final namesById = {
      for (final p in (host.view['players'] as List).cast<Json>())
        p['id']: p['name'],
    };
    check(
      seats.map((s) => s.view['assignedName']).toSet().length == seats.length,
      'Assignments must be one-to-one',
    );
    for (final seat in seats) {
      check(seat.view['assignedName'] != namesById[seat.id], 'Self assignment');
      check(
        !seat.view.containsKey('assignments') &&
            !seat.view.containsKey('results') &&
            !jsonEncode(seat.view).contains('tokenHash'),
        'Private state leaked',
      );
    }
    final seenQuestions = <int>{};
    for (var q = 0; q < 10; q++) {
      final question = host.view['question'] as Json;
      seenQuestions.add(question['id'] as int);
      check(
        ['Everyday', 'Personality'].contains(question['category']),
        'Category filter failed',
      );
      if (q == 0) {
        await rejected(
          () => host.act('answer', {'round': 1, 'index': 0, 'choice': 4}),
        );
        await host.act('answer', {'round': 1, 'index': 0, 'choice': 0});
        await host.act('answer', {'round': 1, 'index': 0, 'choice': 0});
        await rejected(
          () => host.act('answer', {'round': 1, 'index': 0, 'choice': 1}),
        );
      }
      await Future.wait([
        for (var p = q == 0 ? 1 : 0; p < seats.length; p++)
          seats[p].act('answer', {'round': 1, 'index': q, 'choice': p % 4}),
      ]);
      if (q < 9) {
        await until(() => seats.every((s) => s.view['index'] == q + 1));
      } else {
        await until(() => seats.every((s) => s.view['phase'] == 'guessing'));
      }
      if (q == 4) {
        final returning = seats[2];
        final before = returning.events;
        await returning.stream?.cancel();
        returning.client.close();
        returning.client = Client(url);
        returning.watch();
        await until(() => returning.events > before);
        check(returning.view['index'] == 5, 'Reconnect lost room progress');
      }
    }
    check(seenQuestions.length == 10, 'Questions repeated');
    for (final seat in seats) {
      check((seat.view['clues'] as List).length == 10, 'Clues missing');
      check(!seat.view.containsKey('results'), 'Early reveal');
    }
    await Future.wait(
      seats.map((seat) {
        final actor = seats.firstWhere(
          (other) => other.view['assignedName'] == namesById[seat.id],
        );
        return seat.act('guess', {'round': 1, 'playerId': actor.id});
      }),
    );
    await until(() => seats.every((s) => s.view['phase'] == 'reveal'));
    check(
      (host.view['results'] as List).every((r) => r['correct'] == true),
      'Guess scoring failed',
    );
    await host.act('reset');
    await until(() => seats.every((s) => s.view['phase'] == 'lobby'));
    await host.act('start');
    await until(() => seats.every((s) => s.view['round'] == 2));
    await rejected(
      () => host.act('answer', {'round': 1, 'index': 0, 'choice': 0}),
    );
    await host.act('reset');
    await until(() => seats.every((s) => s.view['phase'] == 'lobby'));
    print(
      'PASS: four real clients, concurrent joins and answers, 10 questions, WebSocket updates, reconnect, privacy, guesses, replay, and stale-action rejection.',
    );
    print(
      'Room: ${host.code}; retained in the local test database for inspection.',
    );
  } finally {
    for (final seat in seats) {
      await seat.stream?.cancel();
      seat.client.close();
    }
    hostClient.close();
  }
}
