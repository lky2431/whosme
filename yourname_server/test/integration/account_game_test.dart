import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:yourname_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

Map<String, dynamic> read(String value) =>
    jsonDecode(value) as Map<String, dynamic>;

void main() {
  withServerpod('Optional player accounts', (sessions, endpoints) {
    final alice = sessions.copyWith(
      authentication: AuthenticationOverride.authenticationInfo('alice', {}),
    );
    final bob = sessions.copyWith(
      authentication: AuthenticationOverride.authenticationInfo('bob', {}),
    );
    test('host departure deletes room and saved seats for everyone', () async {
      final host = read(
        await endpoints.game.createRoom(
          alice,
          'Alice',
          1,
          ['Everyday'],
          avatarIndex: 0,
        ),
      );
      final code = host['code'] as String;
      final guest = read(
        await endpoints.game.joinRoom(
          bob,
          code,
          'Bob',
          avatarIndex: 1,
        ),
      );
      final session = sessions.build();
      final room = (await GameRoom.db.findFirstRow(
        session,
        where: (t) => t.code.equals(code),
      ))!;
      expect(
        await SavedSeat.db.count(
          session,
          where: (t) => t.roomId.equals(room.id!),
        ),
        2,
      );
      final updates = StreamIterator(
        endpoints.game.watch(bob, code, guest['token'] as String),
      );
      addTearDown(updates.cancel);
      expect(
        await updates.moveNext().timeout(const Duration(seconds: 10)),
        isTrue,
      );
      final closedUpdate = expectLater(
        updates.moveNext().timeout(const Duration(seconds: 10)),
        throwsA(isA<GameException>()),
      );
      await endpoints.game.act(
        alice,
        code,
        host['token'] as String,
        'leave',
        '{}',
      );
      await closedUpdate;
      expect(await GameRoom.db.findById(session, room.id!), isNull);
      expect(
        await SavedSeat.db.count(
          session,
          where: (t) => t.roomId.equals(room.id!),
        ),
        0,
      );
      await expectLater(
        endpoints.game.snapshot(bob, code, guest['token'] as String),
        throwsA(isA<GameException>()),
      );
      await expectLater(
        endpoints.game.joinRoom(sessions, code, 'New', avatarIndex: 0),
        throwsA(isA<GameException>()),
      );
      await expectLater(
        endpoints.game.resume(bob, code),
        throwsA(isA<GameException>()),
      );
      expect(read(await endpoints.account.games(bob))['active'], isEmpty);
    });
    test('guest can host with an avatar but cannot access accounts', () async {
      final seat = read(
        await endpoints.game.createRoom(sessions, 'Guest', 1, [
          'Everyday',
        ], avatarIndex: 9),
      );
      expect(seat['view']['players'][0]['avatarIndex'], 9);
      expect(jsonEncode(seat['view']), isNot(contains('tokenHash')));
      expect(jsonEncode(seat['view']), isNot(contains('userId')));
      await expectLater(
        endpoints.account.profile(sessions),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
      await expectLater(
        endpoints.game.createRoom(sessions, 'Bad', 1, [
          'Everyday',
        ], avatarIndex: 10),
        throwsA(isA<GameException>()),
      );
      final saved = await SavedSeat.db.find(sessions.build());
      expect(saved, isEmpty);
    });
    test(
      'profile persists and another account cannot resume or use its seat',
      () async {
        await endpoints.account.saveProfile(alice, 'Alice', 4, null);
        expect(read(await endpoints.account.profile(alice))['avatarIndex'], 4);
        final seat = read(
          await endpoints.game.createRoom(alice, 'Alice', 1, [
            'Everyday',
          ], avatarIndex: 0),
        );
        expect(seat['view']['players'][0]['avatarIndex'], 4);
        final code = seat['code'] as String, token = seat['token'] as String;
        await expectLater(
          endpoints.game.snapshot(bob, code, token),
          throwsA(isA<GameException>()),
        );
        await expectLater(
          endpoints.game.snapshot(sessions, code, token),
          throwsA(isA<GameException>()),
        );
        await expectLater(
          endpoints.game.resume(bob, code),
          throwsA(isA<GameException>()),
        );
        expect(read(await endpoints.account.games(bob))['active'], isEmpty);
        expect(
          read(await endpoints.account.games(alice))['active'],
          hasLength(1),
        );
        final resumed = read(await endpoints.game.resume(alice, code));
        expect(resumed['view']['selfId'], seat['view']['selfId']);
        expect(resumed['token'], isNot(token));
        await expectLater(
          endpoints.game.snapshot(alice, code, token),
          throwsA(isA<GameException>()),
        );
      },
    );
    test(
      'guest seat can be claimed once without creating another player',
      () async {
        final seat = read(
          await endpoints.game.createRoom(sessions, 'Guest', 1, [
            'Everyday',
          ], avatarIndex: 2),
        );
        final code = seat['code'] as String, token = seat['token'] as String;
        final linked = read(
          await endpoints.game.linkAccount(alice, code, token),
        );
        expect(linked['players'], hasLength(1));
        expect(linked['selfId'], seat['view']['selfId']);
        await endpoints.game.linkAccount(alice, code, token);
        expect(await SavedSeat.db.find(sessions.build()), hasLength(1));
        await expectLater(
          endpoints.game.linkAccount(bob, code, token),
          throwsA(isA<GameException>()),
        );
        await expectLater(
          endpoints.game.joinRoom(alice, code, 'Other name', avatarIndex: 0),
          throwsA(isA<GameException>()),
        );
      },
    );
    test(
      'completed round is private, idempotent, and survives reset and expiry',
      () async {
        final host = read(
          await endpoints.game.createRoom(alice, 'Alice', 1, [
            'Everyday',
          ], avatarIndex: 1),
        );
        final code = host['code'] as String;
        final seats = [
          host,
          read(await endpoints.game.joinRoom(bob, code, 'Bob', avatarIndex: 2)),
          read(
            await endpoints.game.joinRoom(
              sessions,
              code,
              'Cat',
              avatarIndex: 3,
            ),
          ),
          read(
            await endpoints.game.joinRoom(
              sessions,
              code,
              'Dog',
              avatarIndex: 4,
            ),
          ),
        ];
        final builders = [alice, bob, sessions, sessions];
        await endpoints.game.act(
          alice,
          code,
          host['token'] as String,
          'start',
          '{}',
        );
        for (var i = 0; i < 4; i++) {
          await endpoints.game.act(
            builders[i],
            code,
            seats[i]['token'] as String,
            'answer',
            jsonEncode({'round': 1, 'index': 0, 'choice': i}),
          );
        }
        for (var i = 0; i < 4; i++) {
          await endpoints.game.act(
            builders[i],
            code,
            seats[i]['token'] as String,
            'guess',
            jsonEncode({
              'round': 1,
              'playerId': seats[(i + 1) % 4]['view']['selfId'],
            }),
          );
        }
        // Relinking a finished seat must not duplicate the saved round.
        await endpoints.game.linkAccount(alice, code, host['token'] as String);
        final games = read(await endpoints.account.games(alice));
        expect(games['completed'], hasLength(1));
        final id = games['completed'][0]['id'] as int;
        final history = read(await endpoints.account.history(alice, id));
        expect(history['results'], hasLength(4));
        expect(history['clues'], hasLength(1));
        expect(jsonEncode(history), isNot(contains('userId')));
        await expectLater(
          endpoints.account.history(bob, id),
          throwsA(isA<GameException>()),
        );
        await endpoints.game.act(
          alice,
          code,
          host['token'] as String,
          'reset',
          '{}',
        );
        expect(read(await endpoints.account.history(alice, id)), history);
        final session = sessions.build();
        final room = (await GameRoom.db.findFirstRow(
          session,
          where: (t) => t.code.equals(code),
        ))!;
        room.expiresAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 1),
        );
        await GameRoom.db.updateRow(session, room);
        expect(read(await endpoints.account.games(alice))['active'], isEmpty);
        expect(read(await endpoints.account.history(alice, id)), history);
        expect(await GameHistory.db.find(session), hasLength(2));
        room.expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
        await GameRoom.db.updateRow(session, room);
        await endpoints.game.act(
          alice,
          code,
          host['token'] as String,
          'leave',
          '{}',
        );
        expect(await GameRoom.db.findById(session, room.id!), isNull);
        expect(read(await endpoints.account.history(alice, id)), history);
        expect(await GameHistory.db.find(session), hasLength(2));
      },
    );
  });
}
