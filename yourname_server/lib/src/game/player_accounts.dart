import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'game_engine.dart';

/// Account ownership is always taken from the verified Serverpod session.
class PlayerAccounts {
  static String userId(Session session) =>
      session.authenticated?.userIdentifier ??
      GameEngine.fail('Sign in to see your profile and saved games.');

  static Future<PlayerProfile> profile(Session session) async {
    final uid = userId(session);
    return session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtext(@uid))',
        parameters: QueryParameters.named({'uid': uid}),
        transaction: tx,
      );
      return await PlayerProfile.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(uid),
            transaction: tx,
          ) ??
          await PlayerProfile.db.insertRow(
            session,
            PlayerProfile(userId: uid, displayName: '', avatarIndex: 0),
            transaction: tx,
          );
    });
  }

  static Json publicProfile(PlayerProfile p) => {
    'displayName': p.displayName,
    'avatarIndex': p.avatarIndex,
    'avatarImage': p.avatarImage,
  };

  static Future<void> remember(
    Session session,
    GameRoom room,
    Json player,
    Transaction tx,
  ) async {
    final uid = player['userId'] as String?;
    if (uid == null) return;
    final existing = await SavedSeat.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(uid) & t.roomId.equals(room.id!),
      transaction: tx,
    );
    if (existing == null) {
      await SavedSeat.db.insertRow(
        session,
        SavedSeat(
          userId: uid,
          roomId: room.id!,
          playerId: player['id'] as String,
          joinedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
    } else if (existing.playerId != player['id']) {
      existing.playerId = player['id'] as String;
      existing.joinedAt = DateTime.now().toUtc();
      await SavedSeat.db.updateRow(session, existing, transaction: tx);
    }
  }

  /// Snapshot completed rounds before reset/expiry, inside the room transaction.
  static Future<void> archive(
    Session session,
    GameRoom room,
    Json state,
    Transaction tx,
  ) async {
    if (state['phase'] != 'reveal') return;
    for (final player in GameEngine.players(state)) {
      final uid = player['userId'] as String?;
      if (uid == null) continue;
      final existing = await GameHistory.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(uid) &
            t.roomId.equals(room.id!) &
            t.round.equals(state['round'] as int),
        transaction: tx,
      );
      if (existing != null) continue;
      await GameHistory.db.insertRow(
        session,
        GameHistory(
          userId: uid,
          roomId: room.id!,
          round: state['round'] as int,
          completedAt: DateTime.now().toUtc(),
          viewJson: jsonEncode(
            GameEngine.view(state, player['id'] as String, room.code),
          ),
        ),
        transaction: tx,
      );
    }
  }
}
