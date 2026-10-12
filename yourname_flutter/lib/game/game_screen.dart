import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_controller.dart';
import 'account_screen.dart';
import 'player_avatar.dart';
import 'question_chat.dart';
import 'round_overview.dart';
import 'quit_game.dart';

import 'paper_theme.dart';
import 'paper_widgets.dart';
import 'paper_motion.dart';
import 'paper_layout.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.controller,
    this.initialRoomCode,
    this.onOpenProfile,
  });
  final GameController controller;
  final String? initialRoomCode;
  final VoidCallback? onOpenProfile;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _name = TextEditingController(), _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  final Set<String> _categories = {};
  bool _joining = false;
  int _count = 10;
  String? _guess, _questionKey, _reviewPlayer;
  String? _prefilledUser;
  GameController get game => widget.controller;
  @override
  void initState() {
    super.initState();
    _applyRoomLink();
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRoomCode != widget.initialRoomCode) _applyRoomLink();
  }

  void _applyRoomLink() {
    _code.text = widget.initialRoomCode ?? '';
    if (widget.initialRoomCode != null) {
      _joining = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: game,
    builder: (context, _) {
      if (game.account?.signedIn == true &&
          _prefilledUser != game.account?.userId) {
        _prefilledUser = game.account?.userId;
        if (_name.text.isEmpty) _name.text = game.account!.displayName;
      }
      final room = game.room;
      final key = room == null
          ? null
          : '${room['code']}:${room['round']}:${room['phase']}:${room['index']}';
      if (key != _questionKey) {
        if (room != null) _code.clear();
        _questionKey = key;
        _guess = null;
        _reviewPlayer = null;
      }
      if (room?['phase'] == 'questions') {
        return QuestionChat(
          key: ValueKey('${room!['code']}:${room['round']}'),
          game: game,
        );
      }
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(
              PaperLayout.gutter(MediaQuery.sizeOf(context).width),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: chatBlue,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: _header(room),
                    ),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).width < 600 ? 24 : 36,
                    ),
                    if (game.error != null) ...[
                      _error(),
                      SizedBox(height: 20),
                    ],
                    if (room == null && game.hasSeat)
                      _card(
                        Column(
                          children: [
                            Icon(Icons.sync, size: 44),
                            SizedBox(height: 16),
                            Text(context.tr('Reconnecting to your room…')),
                            SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: game.reconnect,
                              child: Text(context.tr('Try again')),
                            ),
                            TextButton(
                              onPressed: game.forget,
                              child: Text(context.tr('Forget saved seat')),
                            ),
                          ],
                        ),
                      )
                    else if (room == null)
                      PaperEntrance(child: _welcome())
                    else
                      _room(room),
                    SizedBox(height: 40),
                    Text(
                      context.tr(
                        'A little imagination. A lot of “that is so you.”',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF66716B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _header(Json? room) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 20,
    runSpacing: 14,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FriendMark(),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'who’s me?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
                color: ink,
              ),
            ),
          ),
        ],
      ),
      if (room == null)
        Text(
          context.tr('a game for your kind of people'),
          style: TextStyle(fontSize: 12, color: mutedInk),
        )
      else
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: game.connected ? forest : mutedInk,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 9),
            Flexible(
              child: Text(
                game.connected
                    ? context.tr('together in {0}', [room['code']])
                    : context.tr('reconnecting…'),
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      const LanguageButton(),
      if (game.account != null)
        TextButton.icon(
          onPressed: game.busy
              ? null
              : widget.onOpenProfile ??
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AccountScreen(game: game),
                      ),
                    ),
          icon: game.account!.signedIn
              ? PlayerAvatar(
                  index: game.avatarIndex,
                  photo: game.avatarImage,
                  size: 28,
                )
              : Icon(Icons.person_outline, size: 20),
          label: Text(
            game.account!.signedIn
                ? context.tr('Profile & games')
                : context.tr('Sign in · optional'),
          ),
        ),
    ],
  );

  Widget _error() => Semantics(
    liveRegion: true,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFE4E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(game.error!),
            style: TextStyle(color: Color(0xFF821B1B)),
          ),
          if (game.room == null && !game.hasSeat)
            TextButton(
              onPressed: game.loading ? null : game.initialize,
              child: Text(context.tr('Retry connection')),
            ),
          if (game.hasSeat && !game.connected)
            Wrap(
              children: [
                TextButton(
                  onPressed: game.reconnect,
                  child: Text(context.tr('Reconnect')),
                ),
                TextButton(
                  onPressed: () => _confirm(
                    context.tr('Forget this seat?'),
                    context.tr(
                      'You will lose access to this player. The host can remove the old seat in the lobby.',
                    ),
                    game.forget,
                  ),
                  child: Text(context.tr('Forget seat')),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _welcome() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = !PaperLayout.columns(context, constraints.maxWidth);
      final intro = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Text(
            context.tr('FRIENDS, WITH A LITTLE TWIST'),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: forest,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 22),
          Text(
            context.tr('How well do you know your people?'),
            style:
                Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(
                  fontSize: constraints.maxWidth < 360
                      ? 30
                      : compact
                      ? 34
                      : 44,
                ),
          ),
          SizedBox(height: 18),
          Text(
            context.tr(
              'Borrow a friend’s name. Think like them.\nThen find the friend who’s pretending to be you.',
            ),
            style: TextStyle(fontSize: 15, height: 1.9, color: mutedInk),
          ),
          if (!compact) ...[SizedBox(height: 28), NameNotes()],
          SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FriendMark(size: 24),
              Text(context.tr('4–20 friends'), style: TextStyle(fontSize: 12)),
              Text(
                context.tr('No account needed'),
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      );
      final form = _card(
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _modeTab(context.tr('Host a room'), false)),
                  SizedBox(width: 8),
                  Expanded(child: _modeTab(context.tr('Join a room'), true)),
                ],
              ),
              SizedBox(height: 28),
              Text(
                _joining
                    ? context.tr('There’s a place for you.')
                    : context.tr('Bring everyone together.'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                _joining
                    ? context.tr('A name and a room code. That’s all.')
                    : context.tr('A few little details, then let’s play.'),
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 26),
              _fieldLabel(context.tr('Your name')),
              TextFormField(
                controller: _name,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: context.tr('What your friends call you'),
                  counterText: '',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? context.tr('Enter your name.')
                    : null,
              ),
              SizedBox(height: 22),
              if (game.account?.signedIn == true)
                Row(
                  children: [
                    PlayerAvatar(
                      index: game.avatarIndex,
                      photo: game.avatarImage,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(context.tr('Playing with your saved avatar')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => AccountScreen(game: game),
                        ),
                      ),
                      child: Text(context.tr('Edit')),
                    ),
                  ],
                )
              else ...[
                _fieldLabel(context.tr('Choose your avatar')),
                AvatarPicker(
                  selected: game.guestAvatarIndex,
                  onSelected: game.busy ? null : game.selectGuestAvatar,
                ),
                SizedBox(height: 8),
                Text(
                  context.tr('Playing as a guest · no sign-in needed.'),
                  style: TextStyle(fontSize: 12, color: mutedInk),
                ),
              ],
              if (_joining) ...[
                SizedBox(height: 22),
                _fieldLabel(context.tr('Room code')),
                TextFormField(
                  controller: _code,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC234',
                    counterText: '',
                  ),
                  validator: (v) => v?.trim().length != 6
                      ? context.tr('Enter the 6-character room code.')
                      : null,
                ),
              ] else ...[
                SizedBox(height: 24),
                _questionCount(),
                SizedBox(height: 24),
                _fieldLabel(context.tr('A little bit of…')),
                if (game.loading)
                  LinearProgressIndicator(minHeight: 2)
                else if (game.categories.isEmpty)
                  Text(
                    context.tr('Connect to the server to load question packs.'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.categories.entries
                        .map(
                          (e) => PaperChoice(
                            label: context.tr(e.key),
                            selected: _categories.contains(e.key),
                            color: _categoryColor(e.key),
                            onPressed: game.busy
                                ? null
                                : () => setState(() {
                                    _categories.contains(e.key)
                                        ? _categories.remove(e.key)
                                        : _categories.add(e.key);
                                  }),
                          ),
                        )
                        .toList(),
                  ),
                SizedBox(height: 10),
                Text(
                  context.tr('Leave these empty for a bit of everything.'),
                  style: TextStyle(fontSize: 11),
                ),
              ],
              SizedBox(height: 28),
              FilledButton(
                onPressed: game.busy || game.loading
                    ? null
                    : () {
                        if (!_form.currentState!.validate()) return;
                        if (_joining) {
                          game.join(_code.text, _name.text);
                        } else {
                          game.create(
                            _name.text,
                            _count,
                            _categories.isEmpty
                                ? game.categories.keys.toList()
                                : _categories.toList(),
                          );
                        }
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        game.busy
                            ? context.tr('Just a moment…')
                            : _joining
                            ? context.tr('Join the party')
                            : context.tr('Create a room'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Text(
                context.tr('Good company is all you need.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      );
      final instructions = [
        _instruction(
          '01',
          context.tr('A name, just for you'),
          context.tr('Secretly become one of your friends.'),
        ),
        _instruction(
          '02',
          context.tr('A little imagination'),
          context.tr('Choose the answers they would choose.'),
        ),
        _instruction(
          '03',
          context.tr('A familiar stranger'),
          context.tr('Read their answers. Find your double.'),
        ),
      ];
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 720 : 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                intro,
                SizedBox(height: 30),
                form,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: intro),
                    SizedBox(width: 56),
                    Expanded(child: form),
                  ],
                ),
              SizedBox(height: compact ? 40 : 64),
              if (compact)
                ...instructions
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < instructions.length; i++) ...[
                      if (i > 0) SizedBox(width: 36),
                      Expanded(child: instructions[i]),
                    ],
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _questionCount() => LayoutBuilder(
    builder: (context, constraints) {
      final label = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('How many questions?'),
            style: TextStyle(color: ink, fontSize: 13),
          ),
          SizedBox(height: 3),
          Text(
            context.tr('A little or a lot. Your call.'),
            style: TextStyle(fontSize: 11),
          ),
        ],
      );
      final counter = Container(
        decoration: BoxDecoration(
          color: mist,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.tr('Fewer questions'),
              onPressed: game.busy || _count <= 2
                  ? null
                  : () => setState(() => _count--),
              icon: Icon(Icons.remove_rounded, size: 16),
            ),
            Semantics(
              liveRegion: true,
              label: context.tr('{0} questions', [_count]),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('$_count', style: TextStyle(color: ink)),
              ),
            ),
            IconButton(
              tooltip: context.tr('More questions'),
              onPressed: game.busy || _count >= 30
                  ? null
                  : () => setState(() => _count++),
              icon: Icon(Icons.add_rounded, size: 16),
            ),
          ],
        ),
      );
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(16) > 21) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [label, SizedBox(height: 12), counter],
        );
      }
      return Row(
        children: [
          Expanded(child: label),
          SizedBox(width: 16),
          counter,
        ],
      );
    },
  );

  Widget _modeTab(String label, bool joining) => TextButton(
    onPressed: game.busy ? null : () => setState(() => _joining = joining),
    style: TextButton.styleFrom(
      backgroundColor: _joining == joining ? mint : Colors.transparent,
      foregroundColor: _joining == joining ? forest : mutedInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Semantics(selected: _joining == joining, child: Text(label)),
  );

  Widget _fieldLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
    ),
  );

  Color _categoryColor(String category) => switch (category) {
    'Food & drink' => butter,
    'Personality' => sky,
    'Would you rather' => Color(0xFFF2E3DF),
    _ => mint,
  };

  Widget _room(Json room) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _tag(
            context.tr('{0} · {1} QUESTIONS', [
              context.tr(room['phase'] as String).toUpperCase(),
              room['count'],
            ]),
            sky,
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: room['code'] as String),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('Room code copied'))),
                );
              }
            },
            icon: Icon(Icons.copy, size: 18),
            label: Text(context.tr('Code: {0}', [room['code']])),
          ),
          QuitGameButton(game: game),
        ],
      ),
      SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final phaseContent = switch (room['phase']) {
            'lobby' => _lobby(room),
            'guessing' => _guessing(room),
            'reveal' => _reveal(room),
            _ => _card(Text(context.tr('This room has closed.'))),
          };
          final content = PaperEntrance(
            key: ValueKey(_questionKey),
            reveal: room['phase'] == 'reveal',
            child: phaseContent,
          );
          if (room['phase'] == 'guessing' || room['phase'] == 'reveal') {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: content,
              ),
            );
          }
          if (!PaperLayout.columns(context, constraints.maxWidth)) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    SizedBox(height: 20),
                    ExpansionTile(
                      key: PageStorageKey('players-${room['code']}'),
                      title: Text(
                        context.tr('The group · {0}', [
                          (room['players'] as List).length,
                        ]),
                      ),
                      subtitle: Text(context.tr('Tap to see your friends')),
                      shape: Border(),
                      collapsedShape: Border(),
                      children: [_players(room, showHeading: false)],
                    ),
                  ],
                ),
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              SizedBox(width: 28),
              SizedBox(width: 300, child: _players(room)),
            ],
          );
        },
      ),
    ],
  );

  Widget _lobby(Json room) {
    final count = (room['players'] as List).length;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tag(context.tr('a room for your people'), butter),
          if (room['roundEndedBy'] != null) ...[
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                context.tr(
                  '{0} left. The round has ended. Invite another friend or start a new round with at least 4 players.',
                  [room['roundEndedBy']],
                ),
              ),
            ),
          ],
          SizedBox(height: 24),
          Text(
            context.tr('Everyone’s welcome.'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: 20),
          Text(context.tr('Share this code with your friends')),
          SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SelectableText(
              room['code'] as String,
              style: TextStyle(
                fontSize: 58,
                letterSpacing: 6,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            (room['categories'] as List)
                .map((c) => context.tr(c as String))
                .join('  /  '),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 24),
          Text(
            count < 4
                ? context.tr(
                    4 - count == 1
                        ? '{0} more friend to get started.'
                        : '{0} more friends to get started.',
                    [4 - count],
                  )
                : context.tr(
                    'Everyone here? Your secret identities are ready to deal.',
                  ),
          ),
          SizedBox(height: 20),
          if (game.isHost)
            FilledButton.icon(
              onPressed: count < 4 || game.busy || !game.connected
                  ? null
                  : () => game.act('start'),
              icon: Icon(Icons.shuffle),
              label: Text(context.tr('Deal the names')),
            )
          else
            Text(
              context.tr('Waiting for the host to start…'),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          SizedBox(height: 12),
          if (game.account?.signedIn != true)
            TextButton.icon(
              onPressed: game.busy ? null : _changeGuestAvatar,
              icon: Icon(Icons.face_outlined),
              label: Text(context.tr('Change avatar')),
            ),
        ],
      ),
      color: mint,
    );
  }

  Widget _guessing(Json room) {
    final locked = room['myGuess'] != null;
    final members = (room['players'] as List).cast<Json>();
    final review = (room['answerReview'] as List? ?? []).cast<Json>();
    final selected = review
        .where((p) => p['playerId'] == _reviewPlayer)
        .firstOrNull;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tag(context.tr('a little detective work'), butter),
          SizedBox(height: 20),
          Text(
            context.tr('Who has your name?'),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          SizedBox(height: 16),
          Text(
            context.tr(
              'Tap a name to read their answers. Who sounds like they were playing you?',
            ),
          ),
          SizedBox(height: 24),
          Text(
            context.tr('Whose answers shall we see?'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final p in review)
                PaperChoice(
                  key: ValueKey('review-${p['playerId']}'),
                  label: p['name'] as String,
                  selected: p == selected,
                  color: sunshine,
                  onPressed: () => setState(
                    () => _reviewPlayer = p == selected
                        ? null
                        : p['playerId'] as String,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (selected == null)
            Text(context.tr('Choose a name above to open their answers.'))
          else ...[
            Text(
              context.tr('Answers by {0}', [selected['name']]),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final answer in selected['answers'] as List)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${answer['number']}. ${context.tr(answer['prompt'] as String)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sunshine,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          context.tr(answer['answer'] as String),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (selected != null || locked) ...[
            const Divider(height: 32),
            Text(
              context.tr('I think it was…'),
              style: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: members
                  .where((p) => p['id'] != room['selfId'])
                  .map(
                    (p) => PaperChoice(
                      label: p['name'] as String,
                      selected: (room['myGuess'] ?? _guess) == p['id'],
                      onPressed: locked || game.busy
                          ? null
                          : () => setState(() => _guess = p['id'] as String),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 24),
            FilledButton(
              onPressed:
                  locked || _guess == null || game.busy || !game.connected
                  ? null
                  : () => game.act('guess', {
                      'round': room['round'],
                      'playerId': _guess,
                    }),
              child: Text(
                locked
                    ? context.tr('Guess locked in')
                    : context.tr('This is my double'),
              ),
            ),
          ],
          SizedBox(height: 14),
          Text(
            context.tr('{0} / {1} guesses in. The reveal opens together.', [
              room['guessedCount'],
              members.length,
            ]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _reveal(Json room) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundOverview(room: room),
        SizedBox(height: 24),
        if (game.isHost)
          FilledButton(
            onPressed: game.busy ? null : () => game.act('reset'),
            child: Text(context.tr('Back to lobby · play again')),
          )
        else
          Text(
            context.tr(
              'The host can take everyone back to the lobby for another round.',
            ),
          ),
      ],
    ),
  );

  Widget _players(Json room, {bool showHeading = true}) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeading) ...[
          Text(
            context.tr('The group · {0}', [(room['players'] as List).length]),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 20),
        ],
        for (final player in (room['players'] as List).cast<Json>())
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                PlayerAvatar(
                  index: player['avatarIndex'] as int? ?? 0,
                  photo: player['avatarImage'] as String?,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['id'] == room['selfId']
                            ? context.tr('{0} (you)', [player['name']])
                            : player['name'] as String,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (player['id'] == room['hostId'])
                        Text(
                          context.tr('Host'),
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (player['done'] == true && room['phase'] != 'lobby')
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF286841),
                    semanticLabel: context.tr('Submitted'),
                  ),
                if (game.isHost &&
                    room['phase'] == 'lobby' &&
                    player['id'] != room['selfId'])
                  IconButton(
                    tooltip: context.tr('Remove {0}', [player['name']]),
                    onPressed: game.busy
                        ? null
                        : () => _confirm(
                            context.tr('Remove {0}?', [player['name']]),
                            context.tr(
                              'They can rejoin with the room code before the game starts.',
                            ),
                            () =>
                                game.act('remove', {'playerId': player['id']}),
                          ),
                    icon: Icon(Icons.person_remove_outlined, size: 19),
                  ),
              ],
            ),
          ),
        Divider(),
        SizedBox(height: 12),
        Text(
          context.tr(
            'Keep your screen to yourself. Your secret name is yours to play.',
          ),
          style: TextStyle(fontSize: 13),
        ),
        if (game.isHost &&
            room['phase'] != 'lobby' &&
            room['phase'] != 'reveal') ...[
          SizedBox(height: 16),
          TextButton(
            onPressed: game.busy
                ? null
                : () => _confirm(
                    context.tr('End this round?'),
                    context.tr(
                      'Everyone returns to the lobby. Answers and guesses from this round will be cleared.',
                    ),
                    () => game.act('reset'),
                  ),
            child: Text(context.tr('Return everyone to lobby')),
          ),
        ],
      ],
    ),
  );

  Future<void> _changeGuestAvatar() async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Choose your avatar')),
        content: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: AvatarPicker(
              selected: game.guestAvatarIndex,
              onSelected: (index) => Navigator.pop(context, index),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Cancel')),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    game.selectGuestAvatar(chosen);
    await game.act('avatar', {'avatarIndex': chosen});
  }

  Future<void> _confirm(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Confirm')),
          ),
        ],
      ),
    );
    if (yes == true) await action();
  }

  Widget _instruction(String number, String title, String detail) => Padding(
    padding: EdgeInsets.only(bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            number,
            style: TextStyle(fontSize: 11, color: forest),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ink,
                ),
              ),
              SizedBox(height: 6),
              Text(detail, style: TextStyle(fontSize: 12, height: 1.7)),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _tag(String text, Color color) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: ink,
        ),
      ),
    ),
  );
  Widget _card(Widget child, {Color color = Colors.white}) => LayoutBuilder(
    builder: (context, constraints) => Container(
      padding: EdgeInsets.all(
        constraints.maxWidth < 360
            ? 18
            : constraints.maxWidth < 600
            ? 24
            : 32,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    ),
  );
}
