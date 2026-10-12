import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'paper_theme.dart';
import 'player_avatar.dart';
import 'quit_game.dart';

/// One question per chat page, with a composer anchored to the viewport.
class QuestionChat extends StatefulWidget {
  const QuestionChat({super.key, required this.game});
  final GameController game;
  @override
  State<QuestionChat> createState() => _QuestionChatState();
}

class _QuestionChatState extends State<QuestionChat> {
  int? _viewing, _latest, _draft;
  List<Json> _feed(Json room) {
    final feed = room['questionFeed'] as List?;
    if (feed != null && feed.isNotEmpty) return feed.cast<Json>();
    // Compatibility with a server deployed before question-feed support.
    return [
      {
        ...room['question'] as Json,
        'index': room['index'],
        'myAnswer': room['myAnswer'],
        'submissions': [
          for (final p in (room['players'] as List).cast<Json>())
            if (p['done'] == true) {'playerId': p['id']},
        ],
      },
    ];
  }

  Future<void> _answer(Json room, Json question) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: 640),
      builder: (_) => _AnswerSheet(
        game: widget.game,
        question: question,
        round: room['round'] as int,
        selected: _draft,
      ),
    );
    if (mounted && result != null) setState(() => _draft = result);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.game,
    builder: (context, _) {
      final game = widget.game;
      final room = game.room;
      if (room == null) return SizedBox.shrink();
      if (room['phase'] != 'questions') return SizedBox.shrink();
      final current = room['index'] as int;
      if (_latest != current) {
        if (_viewing == null || _viewing == _latest) _viewing = current;
        _latest = current;
        _draft = null;
      }
      final feed = _feed(room);
      final question =
          feed.where((q) => q['index'] == _viewing).firstOrNull ?? feed.last;
      final index = question['index'] as int;
      final members = (room['players'] as List).cast<Json>();
      final submitted = (question['submissions'] as List).cast<Json>();
      final saved = question['myAnswer'] as int?;
      final previous = feed
          .where((q) => (q['index'] as int) < index)
          .lastOrNull;
      final next = feed.where((q) => (q['index'] as int) > index).firstOrNull;
      return Scaffold(
        backgroundColor: chatBlue,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 880),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: context.tr('Previous question'),
                          onPressed: previous == null
                              ? null
                              : () => setState(
                                  () => _viewing = previous['index'] as int,
                                ),
                          icon: Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                context.tr('THE GROUP CHAT'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.7,
                                ),
                              ),
                              Text(
                                '${index + 1} / ${room['count']}',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const LanguageButton(),
                        IconButton(
                          tooltip: context.tr('Quit game'),
                          onPressed: game.busy
                              ? null
                              : () => confirmQuitGame(context, game),
                          icon: const Icon(Icons.logout),
                        ),
                        IconButton(
                          tooltip: context.tr('Next question'),
                          onPressed: next == null
                              ? null
                              : () => setState(
                                  () => _viewing = next['index'] as int,
                                ),
                          icon: Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: ColoredBox(
                        color: paper,
                        child: ListView(
                          key: PageStorageKey(
                            'chat-${room['code']}-${room['round']}-$index',
                          ),
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                          children: [
                            Center(
                              child: _Pill(
                                label: context.tr(
                                  question['category'] as String,
                                ),
                                color: sky,
                              ),
                            ),
                            SizedBox(height: 14),
                            Text(
                              context.tr(question['prompt'] as String),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: 14),
                            Center(
                              child: _Pill(
                                label: context.tr('You’re playing {0}', [
                                  room['assignedName'],
                                ]),
                                color: sunshine,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              context.tr(
                                'Think like them. Keep everyone guessing.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                            SizedBox(height: 26),
                            if (game.error != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  context.tr(game.error!),
                                  style: TextStyle(
                                    color: Color(0xFFAD291F),
                                  ),
                                ),
                              ),
                            if (submitted.isEmpty)
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.forum_outlined, size: 34),
                                    SizedBox(height: 10),
                                    Text(
                                      context.tr('Someone has to go first!'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: ink,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      context.tr(
                                        'Tap the yellow button below to send your answer.',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            for (final entry in submitted)
                              if (members.any(
                                    (p) => p['id'] == entry['playerId'],
                                  ) &&
                                  (entry['answer'] != null ||
                                      (entry['playerId'] == room['selfId'] &&
                                          saved != null)))
                                _ChatBubble(
                                  player: members.firstWhere(
                                    (p) => p['id'] == entry['playerId'],
                                  ),
                                  own: entry['playerId'] == room['selfId'],
                                  answer:
                                      entry['answer'] as String? ??
                                      (question['choices'] as List)[saved!]
                                          as String,
                                ),
                            SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                context.tr('{0} / {1} answers in', [
                                  submitted.length,
                                  members.length,
                                ]),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            if (submitted.length < members.length)
                              Center(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    for (final p in members.where(
                                      (p) => !submitted.any(
                                        (e) => e['playerId'] == p['id'],
                                      ),
                                    ))
                                      Tooltip(
                                        message: context.tr('{0} is thinking', [
                                          p['name'],
                                        ]),
                                        child: Opacity(
                                          opacity: .6,
                                          child: PlayerAvatar(
                                            index:
                                                p['avatarIndex'] as int? ?? 0,
                                            photo: p['avatarImage'] as String?,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ColoredBox(
                    color: paper,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: context.tr('See the group'),
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              builder: (context) => SafeArea(
                                child: ListView(
                                  padding: EdgeInsets.all(20),
                                  children: [
                                    if (game.isHost)
                                      TextButton.icon(
                                        icon: Icon(Icons.restart_alt),
                                        label: Text(
                                          context.tr(
                                            'End round and return to lobby',
                                          ),
                                        ),
                                        onPressed: game.busy
                                            ? null
                                            : () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      AlertDialog(
                                                        title: Text(
                                                          context.tr(
                                                            'End this round?',
                                                          ),
                                                        ),
                                                        content: Text(
                                                          context.tr(
                                                            'Everyone will return to the lobby. Answers from this unfinished round will be cleared.',
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  false,
                                                                ),
                                                            child: Text(
                                                              context.tr(
                                                                'Keep playing',
                                                              ),
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  dialogContext,
                                                                  true,
                                                                ),
                                                            child: Text(
                                                              context.tr(
                                                                'End round',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (confirmed == true) {
                                                  await game.act('reset');
                                                  if (context.mounted &&
                                                      game.error == null &&
                                                      ModalRoute.of(
                                                            context,
                                                          )?.isCurrent ==
                                                          true) {
                                                    Navigator.pop(context);
                                                  }
                                                }
                                              },
                                      ),
                                    Text(
                                      context.tr('The group · {0}', [
                                        members.length,
                                      ]),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    for (final p in members)
                                      ListTile(
                                        leading: PlayerAvatar(
                                          index: p['avatarIndex'] as int? ?? 0,
                                          photo: p['avatarImage'] as String?,
                                        ),
                                        title: Text(
                                          p['id'] == room['selfId']
                                              ? context.tr('{0} (you)', [
                                                  p['name'],
                                                ])
                                              : p['name'] as String,
                                        ),
                                        subtitle: Text(
                                          submitted.any(
                                                (e) => e['playerId'] == p['id'],
                                              )
                                              ? context.tr('Answer locked in')
                                              : context.tr('Thinking…'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            icon: Icon(Icons.people_alt_outlined),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: index != current
                                  ? () => setState(() => _viewing = current)
                                  : saved != null ||
                                        game.busy ||
                                        !game.connected
                                  ? null
                                  : () => _answer(room, question),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      index != current
                                          ? context.tr('Back to live question')
                                          : !game.connected
                                          ? context.tr('Reconnecting…')
                                          : saved != null
                                          ? context.tr('Answer sent!')
                                          : context.tr('Your turn!'),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: ink,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      saved != null ? Icons.check : Icons.add,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!game.connected)
                            IconButton(
                              tooltip: context.tr('Reconnect'),
                              onPressed: game.reconnect,
                              icon: Icon(Icons.refresh),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.player,
    required this.own,
    required this.answer,
  });
  final Json player;
  final bool own;
  final String answer;
  @override
  Widget build(BuildContext context) {
    final avatar = PlayerAvatar(
      index: player['avatarIndex'] as int? ?? 0,
      photo: player['avatarImage'] as String?,
      size: 42,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: own
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!own) ...[avatar, SizedBox(width: 10)],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 440),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: own ? sunshine : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(own ? 22 : 5),
                  bottomRight: Radius.circular(own ? 5 : 22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    own ? context.tr('You') : player['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.tr(answer),
                    style: TextStyle(
                      fontSize: 16,
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (own) ...[SizedBox(width: 10), avatar],
        ],
      ),
    );
  }
}

class _AnswerSheet extends StatefulWidget {
  const _AnswerSheet({
    required this.game,
    required this.question,
    required this.round,
    this.selected,
  });
  final GameController game;
  final Json question;
  final int round;
  final int? selected;
  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  int? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.game,
    builder: (context, _) {
      final room = widget.game.room;
      final active =
          room?['phase'] == 'questions' &&
          room?['round'] == widget.round &&
          room?['index'] == widget.question['index'];
      final locked = !active || room?['myAnswer'] != null;
      final choices = (widget.question['choices'] as List).cast<String>();
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('What would {0} say?', [
                  room?['assignedName'] ?? '…',
                ]),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(context.tr(widget.question['prompt'] as String)),
              SizedBox(height: 20),
              for (var i = 0; i < choices.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TextButton(
                    onPressed: locked || widget.game.busy
                        ? null
                        : () => setState(() => _selected = i),
                    style: TextButton.styleFrom(
                      backgroundColor: _selected == i ? ink : Colors.white,
                      foregroundColor: _selected == i ? Colors.white : ink,
                      disabledForegroundColor: mutedInk,
                      padding: EdgeInsets.all(18),
                    ),
                    child: Row(
                      children: [
                        Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            context.tr(choices[i]),
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                        if (_selected == i) Icon(Icons.check_circle_outline),
                      ],
                    ),
                  ),
                ),
              if (widget.game.error != null)
                Text(
                  context.tr(widget.game.error!),
                  style: TextStyle(color: Color(0xFFAD291F)),
                ),
              SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _selected == null ||
                        locked ||
                        widget.game.busy ||
                        !widget.game.connected
                    ? null
                    : () async {
                        await widget.game.act('answer', {
                          'round': widget.round,
                          'index': widget.question['index'],
                          'choice': _selected,
                        });
                        if (context.mounted && widget.game.error == null) {
                          Navigator.pop(context, _selected);
                        }
                      },
                child: Text(
                  !active
                      ? context.tr('This question has ended')
                      : locked
                      ? context.tr('Answer locked in')
                      : widget.game.busy
                      ? context.tr('Sending…')
                      : context.tr('Lock in my answer'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: Text(context.tr('Back to chat')),
              ),
            ],
          ),
        ),
      );
    },
  );
}
