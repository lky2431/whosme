import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import 'game_controller.dart';

Future<bool> confirmQuitGame(BuildContext context, GameController game) async {
  if (game.busy) return false;
  final room = game.room;
  if (room == null) return false;
  final active = room['phase'] == 'questions' || room['phase'] == 'guessing';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(context.tr(active ? 'Quit this game?' : 'Leave this room?')),
      content: Text(
        context.tr(
          game.isHost
              ? 'You are the host. Leaving will close this room for everyone and return all players to the home screen.'
              : active
              ? 'If you quit, this round ends for everyone. Unfinished answers and guesses will be cleared, and the others will return to the lobby.'
              : 'You will leave this room. The other players can stay.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('Stay')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(active ? 'Quit game' : 'Leave room')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  // Do not apply an old confirmation to a newly started round or another room.
  if (game.room?['code'] != room['code'] ||
      game.room?['round'] != room['round'] ||
      (!active && game.room?['phase'] != room['phase'])) {
    return false;
  }
  await game.act('leave');
  return !game.hasSeat;
}

class QuitGameButton extends StatelessWidget {
  const QuitGameButton({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: game.busy ? null : () => confirmQuitGame(context, game),
    icon: const Icon(Icons.logout, size: 20),
    label: Text(
      context.tr(
        game.room?['phase'] == 'questions' || game.room?['phase'] == 'guessing'
            ? 'Quit game'
            : 'Leave room',
      ),
    ),
  );
}
