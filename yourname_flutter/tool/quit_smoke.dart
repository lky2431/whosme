// Local preview only: dart run tool/quit_smoke.dart
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:yourname_client/yourname_client.dart';
import 'multiplayer_smoke.dart' show Seat, Json, check, rejected;

Future<void> main() async {
  const url = 'http://127.0.0.1:18080/';
  final seats = <Seat>[];
  final updates = <StreamIterator<String>>[];
  try {
    final client = Client(url);
    final host = Seat(
      client,
      jsonDecode(
            await client.game.createRoom('Quit host', 1, [
              'Everyday',
            ], avatarIndex: 0),
          )
          as Json,
    );
    seats.add(host);
    for (var i = 1; i < 4; i++) {
      final client = Client(url);
      seats.add(
        Seat(
          client,
          jsonDecode(
                await client.game.joinRoom(
                  host.code,
                  'Friend $i',
                  avatarIndex: i,
                ),
              )
              as Json,
        ),
      );
    }
    await host.act('start');
    for (final seat in seats.skip(1)) {
      final stream = StreamIterator(
        seat.client.game.watch(seat.code, seat.token),
      );
      updates.add(stream);
      check(
        await stream.moveNext().timeout(const Duration(seconds: 10)),
        'Expected initial room state',
      );
    }
    final closed = updates
        .map(
          (stream) => rejected(
            () => stream.moveNext().timeout(const Duration(seconds: 10)),
          ),
        )
        .toList();
    await host.act('leave');
    await Future.wait(closed);
    for (final seat in seats) {
      await rejected(() => seat.client.game.snapshot(seat.code, seat.token));
    }
    await rejected(
      () => client.game.joinRoom(host.code, 'Late', avatarIndex: 0),
    );
    print(
      'PASS: host quit closes every guest stream, invalidates all seats, and blocks rejoining.',
    );
  } finally {
    for (final stream in updates) {
      await stream.cancel();
    }
    for (final seat in seats.reversed) {
      try {
        await seat.act('leave');
      } catch (_) {}
      seat.client.close();
    }
  }
}
