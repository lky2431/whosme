import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'game_engine.dart';
import 'question_bank.dart';
import 'player_accounts.dart';

/// Guest seats use a 256-bit bearer secret. Only its digest is persisted.
/// All room changes acquire a PostgreSQL row lock before applying game rules.
class GameEndpoint extends Endpoint {
  static final _random = Random.secure();
  static String _secret() =>
      base64UrlEncode(List.generate(32, (_) => _random.nextInt(256)));
  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  static String _code(String code) {
    final clean = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z2-9]{6}$').hasMatch(clean)) {
      GameEngine.fail('Enter a 6-character room code.');
    }
    return clean;
  }

  Future<String> categories(Session session) async {
    await QuestionBank.seed(session);
    final questions = await PartyQuestion.db.find(
      session,
      where: (t) => t.enabled.equals(true),
    );
    final counts = <String, int>{};
    for (final q in questions.where((q) => q.choices.length == 4)) {
      counts.update(q.category, (v) => v + 1, ifAbsent: () => 1);
    }
    return jsonEncode(counts);
  }

  Future<String> createRoom(
    Session session,
    String name,
    int questionCount,
    List<String> categories, {
    int avatarIndex = 0,
  }) async {
    GameEngine.validAvatar(avatarIndex);
    final profile = session.isUserSignedIn
        ? await PlayerAccounts.profile(session)
        : null;
    if (categories.length > 20) GameEngine.fail('Too many categories.');
    final available = (jsonDecode(await this.categories(session)) as Json);
    final selected = categories.toSet().toList();
    if (selected.any((c) => !available.containsKey(c))) {
      GameEngine.fail('Choose valid categories.');
    }
    final count = selected.fold<int>(0, (n, c) => n + (available[c] as int));
    if (count < questionCount) {
      GameEngine.fail('Choose fewer questions or more categories.');
    }
    final token = _secret();
    final id = _secret().substring(0, 16);
    final state = GameEngine.create(
      id,
      name,
      _hash(token),
      questionCount,
      selected,
    );
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final player = GameEngine.players(state).single;
    player['avatarIndex'] = profile?.avatarIndex ?? avatarIndex;
    player['avatarImage'] = profile?.avatarImage;
    player['userId'] = session.authenticated?.userIdentifier;
    // Serialize code allocation; the unique index remains the final safeguard.
    final code = await session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(572020)',
        transaction: transaction,
      );
      String code;
      do {
        code = List.generate(
          6,
          (_) => alphabet[_random.nextInt(alphabet.length)],
        ).join();
      } while (await GameRoom.db.findFirstRow(
            session,
            where: (t) => t.code.equals(code),
            transaction: transaction,
          ) !=
          null);
      final savedRoom = await GameRoom.db.insertRow(
        session,
        GameRoom(
          code: code,
          stateJson: jsonEncode(state),
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 24)),
        ),
        transaction: transaction,
      );
      await PlayerAccounts.remember(session, savedRoom, player, transaction);
      return code;
    });
    return jsonEncode({
      'code': code,
      'token': token,
      'view': GameEngine.view(state, id, code),
    });
  }

  Future<GameRoom> _room(
    Session session,
    String code, {
    Transaction? transaction,
    bool lock = false,
  }) async {
    final room = await GameRoom.db.findFirstRow(
      session,
      where: (t) => t.code.equals(code),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
    );
    if (room == null || room.expiresAt.isBefore(DateTime.now().toUtc())) {
      GameEngine.fail(
        'Room not found or expired. Ask the host for a new code.',
      );
    }
    return room;
  }

  Future<void> _notify(Session session, String code) async {
    // Local instant delivery; the stream's reconciliation tick also observes
    // changes made on another server when Redis is not configured.
    await session.messages.postMessage('party:$code', RoomPulse(code: code));
  }

  Future<String> joinRoom(
    Session session,
    String code,
    String name, {
    int avatarIndex = 0,
  }) async {
    GameEngine.validAvatar(avatarIndex);
    final profile = session.isUserSignedIn
        ? await PlayerAccounts.profile(session)
        : null;
    code = _code(code);
    final token = _secret();
    final id = _secret().substring(0, 16);
    final view = await session.db.transaction((transaction) async {
      final room = await _room(
        session,
        code,
        transaction: transaction,
        lock: true,
      );
      final state = jsonDecode(room.stateJson) as Json;
      final uid = session.authenticated?.userIdentifier;
      if (uid != null &&
          GameEngine.players(state).any((p) => p['userId'] == uid)) {
        GameEngine.fail(
          'You already have a seat here. Resume it from My games.',
        );
      }
      GameEngine.join(state, id, name, _hash(token));
      final player = GameEngine.players(state).last;
      player['avatarIndex'] = profile?.avatarIndex ?? avatarIndex;
      player['avatarImage'] = profile?.avatarImage;
      player['userId'] = uid;
      await PlayerAccounts.remember(session, room, player, transaction);
      state['version'] = (state['version'] as int) + 1;
      room.stateJson = jsonEncode(state);
      await GameRoom.db.updateRow(session, room, transaction: transaction);
      return GameEngine.view(state, id, code);
    });
    await _notify(session, code);
    return jsonEncode({'code': code, 'token': token, 'view': view});
  }

  Future<String> snapshot(Session session, String code, String token) async {
    code = _code(code);
    final state = jsonDecode((await _room(session, code)).stateJson) as Json;
    final player = GameEngine.authenticate(state, _hash(token));
    GameEngine.authorizeAccount(player, session.authenticated?.userIdentifier);
    return jsonEncode(GameEngine.view(state, player['id'] as String, code));
  }

  Future<String> act(
    Session session,
    String code,
    String token,
    String action,
    String payloadJson,
  ) async {
    code = _code(code);
    Json payload;
    try {
      payload = jsonDecode(payloadJson) as Json;
    } catch (_) {
      GameEngine.fail('Invalid action data.');
    }
    final result = await session.db.transaction((transaction) async {
      final room = await _room(
        session,
        code,
        transaction: transaction,
        lock: true,
      );
      final state = jsonDecode(room.stateJson) as Json;
      final player = GameEngine.authenticate(state, _hash(token));
      GameEngine.authorizeAccount(
        player,
        session.authenticated?.userIdentifier,
      );
      final id = player['id'] as String;
      if (action == 'avatar') {
        final index = payload['avatarIndex'];
        if (index is! int) GameEngine.fail('Choose an avatar.');
        GameEngine.validAvatar(index);
        if (state['phase'] != 'lobby') {
          GameEngine.fail('Change your avatar in the lobby.');
        }
        player['avatarIndex'] = index;
        player['avatarImage'] = null;
      } else if (action == 'start') {
        GameEngine.hostOnly(state, id);
        final rows = await PartyQuestion.db.find(
          session,
          where: (t) =>
              t.enabled.equals(true) &
              t.category.inSet(
                (state['categories'] as List).cast<String>().toSet(),
              ),
          transaction: transaction,
        );
        GameEngine.start(
          state,
          id,
          rows
              .where((q) => q.choices.length == 4)
              .map(
                (q) => <String, dynamic>{
                  'id': q.id,
                  'category': q.category,
                  'prompt': q.prompt,
                  'choices': q.choices,
                },
              )
              .toList(),
          _random,
        );
      } else {
        // Preserve completed results before leaving clears round assignments.
        if (action == 'leave') {
          await PlayerAccounts.archive(session, room, state, transaction);
        }
        GameEngine.act(state, id, action, payload);
      }
      if (state['phase'] == 'closed') {
        await SavedSeat.db.deleteWhere(
          session,
          where: (t) => t.roomId.equals(room.id!),
          transaction: transaction,
        );
        await GameRoom.db.deleteRow(session, room, transaction: transaction);
        return '{}';
      }
      if (action == 'reset') {
        for (final member in GameEngine.players(state)) {
          final uid = member['userId'] as String?;
          if (uid == null) continue;
          final profile = await PlayerProfile.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(uid),
            transaction: transaction,
          );
          if (profile != null) {
            member['avatarIndex'] = profile.avatarIndex;
            member['avatarImage'] = profile.avatarImage;
          }
        }
      }
      await PlayerAccounts.archive(session, room, state, transaction);
      state['version'] = (state['version'] as int) + 1;
      room.stateJson = jsonEncode(state);
      await GameRoom.db.updateRow(session, room, transaction: transaction);
      return action == 'leave'
          ? '{}'
          : jsonEncode(GameEngine.view(state, id, code));
    });
    await _notify(session, code);
    return result;
  }

  /// Claim a guest seat after login, or refresh its profile avatar.
  Future<String> linkAccount(Session session, String code, String token) async {
    final uid = PlayerAccounts.userId(session);
    final profile = await PlayerAccounts.profile(session);
    code = _code(code);
    final result = await session.db.transaction((tx) async {
      final room = await _room(session, code, transaction: tx, lock: true);
      final state = jsonDecode(room.stateJson) as Json;
      final player = GameEngine.authenticate(state, _hash(token));
      GameEngine.authorizeAccount(player, uid);
      if (GameEngine.players(
        state,
      ).any((p) => p['userId'] == uid && p['id'] != player['id'])) {
        GameEngine.fail('This account already has another seat in this room.');
      }
      player['userId'] = uid;
      // Keep each player's appearance stable while a round is being played.
      if (state['phase'] == 'lobby') {
        player['avatarIndex'] = profile.avatarIndex;
        player['avatarImage'] = profile.avatarImage;
      }
      await PlayerAccounts.remember(session, room, player, tx);
      await PlayerAccounts.archive(session, room, state, tx);
      state['version'] = (state['version'] as int) + 1;
      room.stateJson = jsonEncode(state);
      await GameRoom.db.updateRow(session, room, transaction: tx);
      return jsonEncode(GameEngine.view(state, player['id'] as String, code));
    });
    await _notify(session, code);
    return result;
  }

  /// Restores only the caller's saved seat, with a new bearer secret.
  Future<String> resume(Session session, String code) async {
    final uid = PlayerAccounts.userId(session);
    code = _code(code);
    final token = _secret();
    final view = await session.db.transaction((tx) async {
      final room = await _room(session, code, transaction: tx, lock: true);
      final seat = await SavedSeat.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(uid) & t.roomId.equals(room.id!),
        transaction: tx,
      );
      final state = jsonDecode(room.stateJson) as Json;
      final player = GameEngine.players(state)
          .where((p) => p['id'] == seat?.playerId && p['userId'] == uid)
          .firstOrNull;
      if (player == null || state['phase'] == 'closed') {
        GameEngine.fail('Your seat is no longer available.');
      }
      player['tokenHash'] = _hash(token);
      state['version'] = (state['version'] as int) + 1;
      room.stateJson = jsonEncode(state);
      await GameRoom.db.updateRow(session, room, transaction: tx);
      return GameEngine.view(state, player['id'] as String, code);
    });
    await _notify(session, code);
    return jsonEncode({'code': code, 'token': token, 'view': view});
  }

  /// Native Serverpod streaming method: personalized updates over WebSocket.
  Stream<String> watch(Session session, String code, String token) async* {
    code = _code(code);
    await snapshot(session, code, token); // Authenticate before subscribing.
    final ticks = StreamController<RoomPulse>();
    final subscription = session.messages
        .createStream<RoomPulse>('party:$code')
        .listen(ticks.add, onError: ticks.addError);
    // Reconcile across server instances and check room expiry even when idle.
    final timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ticks.add(RoomPulse(code: code)),
    );
    ticks.add(RoomPulse(code: code));
    String? previous;
    try {
      await for (final _ in ticks.stream) {
        final current = await snapshot(session, code, token);
        if (current != previous) {
          previous = current;
          yield current;
        }
      }
    } finally {
      timer.cancel();
      await subscription.cancel();
      await ticks.close();
    }
  }
}
