import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:image/image.dart' as img;
import '../generated/protocol.dart';
import 'game_engine.dart';
import 'player_accounts.dart';

class AccountEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<String> profile(Session session) async => jsonEncode(
    PlayerAccounts.publicProfile(await PlayerAccounts.profile(session)),
  );

  Future<String> saveProfile(
    Session session,
    String displayName,
    int avatarIndex,
    String? avatarImage,
  ) async {
    final name = GameEngine.validName(displayName);
    GameEngine.validAvatar(avatarIndex);
    final photo = normalizePhoto(avatarImage);
    final profile = await PlayerAccounts.profile(session);
    profile.displayName = name;
    profile.avatarIndex = avatarIndex;
    profile.avatarImage = photo;
    await PlayerProfile.db.updateRow(session, profile);
    return jsonEncode(PlayerAccounts.publicProfile(profile));
  }

  /// Accept only small JPEG/PNG images. Re-encode to strip metadata and bound
  /// database/room payload size; never fetch a caller-supplied image URL.
  static String? normalizePhoto(String? value) {
    if (value == null) return null;
    if (value.length > 1400000) {
      GameEngine.fail('Choose a photo smaller than 1 MB.');
    }
    try {
      final bytes = base64Decode(value);
      if (bytes.length > 1024 * 1024) {
        GameEngine.fail('Choose a photo smaller than 1 MB.');
      }
      final decoder = img.findDecoderForData(bytes);
      if (decoder is! img.JpegDecoder && decoder is! img.PngDecoder) {
        GameEngine.fail('Choose a JPEG or PNG photo.');
      }
      final info = decoder!.startDecode(bytes);
      if (info == null || info.width > 2048 || info.height > 2048) {
        GameEngine.fail('Choose a photo up to 2048 × 2048 pixels.');
      }
      final decoded = decoder.decodeFrame(0);
      if (decoded == null) GameEngine.fail('This photo could not be read.');
      final small = img.copyResizeCropSquare(
        img.bakeOrientation(decoded),
        size: 96,
      );
      return base64Encode(img.encodeJpg(small, quality: 80));
    } on GameException {
      rethrow;
    } catch (_) {
      GameEngine.fail('Choose a valid JPEG or PNG photo.');
    }
  }

  Future<String> games(Session session) async {
    final uid = PlayerAccounts.userId(session);
    final seats = await SavedSeat.db.find(
      session,
      where: (t) => t.userId.equals(uid),
      orderBy: (t) => t.joinedAt,
      orderDescending: true,
      limit: 100,
    );
    final active = <Json>[];
    final now = DateTime.now().toUtc();
    for (final seat in seats) {
      final room = await GameRoom.db.findById(session, seat.roomId);
      if (room == null || !room.expiresAt.isAfter(now)) continue;
      final state = jsonDecode(room.stateJson) as Json;
      if (state['phase'] == 'closed') continue;
      if (!GameEngine.players(
        state,
      ).any((p) => p['id'] == seat.playerId && p['userId'] == uid)) {
        continue;
      }
      active.add({
        'code': room.code,
        'phase': state['phase'],
        'playerCount': GameEngine.players(state).length,
        'expiresAt': room.expiresAt.toIso8601String(),
      });
    }
    final completed = await GameHistory.db.find(
      session,
      where: (t) => t.userId.equals(uid),
      orderBy: (t) => t.completedAt,
      orderDescending: true,
      limit: 100,
    );
    return jsonEncode({
      'active': active,
      'completed': [
        for (final game in completed)
          {
            'id': game.id,
            'round': game.round,
            'completedAt': game.completedAt.toIso8601String(),
            'code': (jsonDecode(game.viewJson) as Json)['code'],
          },
      ],
    });
  }

  Future<String> history(Session session, int id) async {
    final game = await GameHistory.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(id) & t.userId.equals(PlayerAccounts.userId(session)),
    );
    if (game == null) GameEngine.fail('Saved game not found.');
    return game.viewJson;
  }
}
