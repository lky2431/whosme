import '../l10n/app_language.dart';
import 'round_overview.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'account_controller.dart';
import 'game_controller.dart';
import 'player_avatar.dart';
import 'paper_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.game});
  final GameController game;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _name = TextEditingController();
  bool _register = false, _photoBusy = false;
  String? _loadedUser, _photo, _localError;
  int _avatar = 0;
  AccountController get account => widget.game.account!;
  @override
  void initState() {
    super.initState();
    if (account.signedIn) account.refresh();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _loadProfile() {
    if (!account.signedIn) {
      _loadedUser = null;
      return;
    }
    if (_loadedUser == account.userId) return;
    _loadedUser = account.userId;
    _name.text = account.displayName;
    _avatar = account.avatarIndex;
    _photo = account.avatarImage;
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _photoBusy = true;
      _localError = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file == null) return;
      if (await file.length() > 1024 * 1024) {
        throw FormatException(
          'Choose a JPEG or PNG photo smaller than 1 MB.',
        );
      }
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = base64Encode(bytes));
    } catch (_) {
      if (mounted) {
        setState(
          () => _localError =
              'Could not open this photo. Choose a JPEG or PNG smaller than 1 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: account,
    builder: (context, _) {
      _loadProfile();
      return Scaffold(
        appBar: AppBar(
          actions: const [LanguageButton()],
          title: Text(
            account.signedIn
                ? context.tr('Your corner')
                : context.tr('Keep the memories'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (account.error != null || _localError != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          context.tr(_localError ?? account.error!),
                          style: TextStyle(color: Color(0xFF821B1B)),
                        ),
                      ),
                    ),
                  if (account.message != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          context.tr(account.message!),
                          style: TextStyle(color: forest),
                        ),
                      ),
                    ),
                  if (account.signedIn) ..._profile() else ..._signIn(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _signIn() => [
    Text(
      context.tr('The party is open to everyone.'),
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    SizedBox(height: 12),
    Text(
      context.tr(
        'Sign in to keep your games across devices and make your avatar your own. Playing as a guest is always welcome.',
      ),
    ),
    SizedBox(height: 24),
    if (!account.ready) ...[
      if (account.preparingSignIn)
        LinearProgressIndicator()
      else
        TextButton.icon(
          onPressed: account.prepareSignIn,
          icon: Icon(Icons.refresh),
          label: Text(context.tr('Retry sign-in connection')),
        ),
      SizedBox(height: 16),
    ],
    if (kIsWeb) ...[
      OutlinedButton.icon(
        onPressed: account.busy || !account.ready ? null : account.googleSignIn,
        icon: Icon(Icons.login),
        label: Text(context.tr('Continue with Google')),
      ),
      SizedBox(height: 20),
      Text(context.tr('or use your email'), textAlign: TextAlign.center),
      SizedBox(height: 20),
    ],
    TextField(
      controller: _email,
      enabled: !account.busy,
      keyboardType: TextInputType.emailAddress,
      autofillHints: [AutofillHints.email],
      decoration: InputDecoration(labelText: context.tr('Email')),
    ),
    SizedBox(height: 16),
    TextField(
      controller: _password,
      enabled: !account.busy,
      obscureText: true,
      autofillHints: [
        _register ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: context.tr('Password'),
        helperText: context.tr('At least 6 characters'),
      ),
    ),
    SizedBox(height: 20),
    FilledButton(
      onPressed: account.busy || !account.ready
          ? null
          : () async {
              if (_email.text.trim().isEmpty || _password.text.length < 6) {
                setState(
                  () => _localError =
                      'Enter your email and a password of at least 6 characters.',
                );
                return;
              }
              setState(() => _localError = null);
              if (_register) {
                await account.register(_email.text, _password.text);
              } else {
                await account.emailSignIn(_email.text, _password.text);
              }
            },
      child: Text(
        account.busy
            ? context.tr('Just a moment…')
            : _register
            ? context.tr('Create an account')
            : context.tr('Sign in'),
      ),
    ),
    TextButton(
      onPressed: account.busy
          ? null
          : () => setState(() {
              _register = !_register;
              _localError = null;
            }),
      child: Text(
        _register
            ? context.tr('Already have an account? Sign in')
            : context.tr('New here? Create an account'),
      ),
    ),
    Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: account.busy || !account.ready
              ? null
              : () => account.resetPassword(_email.text),
          child: Text(context.tr('Forgot password?')),
        ),
        TextButton(
          onPressed: account.busy || !account.ready
              ? null
              : account.resendVerification,
          child: Text(context.tr('Resend verification email')),
        ),
      ],
    ),
    SizedBox(height: 16),
    TextButton.icon(
      onPressed: account.busy ? null : () => Navigator.pop(context),
      icon: Icon(Icons.arrow_back),
      label: Text(context.tr('Continue as guest')),
    ),
  ];

  List<Widget> _profile() => [
    Text(
      context.tr('A familiar face.'),
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    SizedBox(height: 20),
    Center(
      child: PlayerAvatar(index: _avatar, photo: _photo, size: 96),
    ),
    SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: account.busy || _photoBusy ? null : _pickPhoto,
      icon: Icon(Icons.add_photo_alternate_outlined),
      label: Text(
        _photoBusy
            ? context.tr('Opening photo…')
            : context.tr('Upload a photo'),
      ),
    ),
    Text(
      context.tr('JPEG or PNG, up to 1 MB. Photos are cropped to a square.'),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: mutedInk),
    ),
    SizedBox(height: 20),
    Text(context.tr('Or choose a little character')),
    SizedBox(height: 12),
    AvatarPicker(
      selected: _photo == null ? _avatar : null,
      onSelected: account.busy
          ? null
          : (value) => setState(() {
              _avatar = value;
              _photo = null;
            }),
    ),
    SizedBox(height: 20),
    TextField(
      controller: _name,
      maxLength: 24,
      enabled: !account.busy,
      decoration: InputDecoration(labelText: context.tr('Your name')),
    ),
    FilledButton(
      onPressed: account.busy || _photoBusy
          ? null
          : () async {
              if (_name.text.trim().isEmpty) {
                setState(() => _localError = 'Enter your name.');
                return;
              }
              setState(() => _localError = null);
              final saved = await account.saveProfile(
                _name.text,
                _avatar,
                _photo,
              );
              if (saved && mounted) {
                setState(() => _photo = account.avatarImage);
              }
            },
      child: Text(
        account.busy ? context.tr('Saving…') : context.tr('Save profile'),
      ),
    ),
    SizedBox(height: 8),
    Text(
      context.tr(
        'Your avatar updates in the lobby. During a round, your current look stays until you return to the lobby.',
      ),
      style: TextStyle(fontSize: 12, color: mutedInk),
    ),
    SizedBox(height: 28),
    OutlinedButton.icon(
      onPressed: account.busy
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => MyGamesScreen(game: widget.game),
              ),
            ),
      icon: Icon(Icons.history),
      label: Text(context.tr('My games')),
    ),
    TextButton(
      onPressed: account.busy
          ? null
          : () async {
              await account.signOut();
              if (mounted && !account.signedIn) Navigator.pop(context);
            },
      child: Text(context.tr('Sign out')),
    ),
  ];
}

class MyGamesScreen extends StatefulWidget {
  const MyGamesScreen({super.key, required this.game});
  final GameController game;
  @override
  State<MyGamesScreen> createState() => _MyGamesScreenState();
}

class _MyGamesScreenState extends State<MyGamesScreen> {
  AccountController get account => widget.game.account!;
  bool _opening = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    account.refresh();
  }

  String _date(dynamic iso) {
    final d = DateTime.parse(iso as String).toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: account,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(context.tr('My games')),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: context.tr('Refresh games'),
            onPressed: account.busy ? null : account.refresh,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (account.busy || _opening) LinearProgressIndicator(),
                if (_error != null || account.error != null)
                  Text(
                    context.tr(_error ?? account.error!),
                    style: TextStyle(color: Color(0xFF821B1B)),
                  ),
                Text(
                  context.tr('Still at the party'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  context.tr(
                    'Rooms stay open for 24 hours. Resuming here moves your seat to this device.',
                  ),
                ),
                SizedBox(height: 12),
                if (!account.busy && (account.games['active'] as List).isEmpty)
                  Text(context.tr('No active rooms yet.')),
                for (final item in account.games['active'] as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Room {0}', [item['code']])),
                    subtitle: Text(
                      context.tr('{0} friends · {1}', [
                        item['playerCount'],
                        context.tr(item['phase'] as String),
                      ]),
                    ),
                    trailing: TextButton(
                      onPressed: _opening || account.busy
                          ? null
                          : () async {
                              setState(() {
                                _opening = true;
                                _error = null;
                              });
                              await widget.game.resume(item['code'] as String);
                              if (!mounted) return;
                              setState(() {
                                _opening = false;
                                _error = widget.game.error;
                              });
                              if (_error == null && context.mounted) {
                                Navigator.popUntil(
                                  context,
                                  (route) => route.isFirst,
                                );
                              }
                            },
                      child: Text(context.tr('Resume')),
                    ),
                  ),
                SizedBox(height: 32),
                Text(
                  context.tr('The memories'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  context.tr(
                    'Your latest 100 completed rounds, saved when everyone finishes guessing.',
                  ),
                ),
                if (!account.busy &&
                    (account.games['completed'] as List).isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      context.tr(
                        'Finish a round while signed in to keep it here.',
                      ),
                    ),
                  ),
                for (final item in account.games['completed'] as List)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.tr('Room {0} · Round {1}', [
                        item['code'],
                        item['round'],
                      ]),
                    ),
                    subtitle: Text(_date(item['completedAt'])),
                    trailing: Icon(Icons.chevron_right),
                    onTap: _opening
                        ? null
                        : () async {
                            setState(() {
                              _opening = true;
                              _error = null;
                            });
                            try {
                              final view = await account.history(
                                item['id'] as int,
                              );
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => _SavedRound(view: view),
                                ),
                              );
                            } catch (_) {
                              if (mounted) {
                                setState(
                                  () => _error =
                                      'Could not load this round. Try again.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _opening = false);
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SavedRound extends StatelessWidget {
  const _SavedRound({required this.view});
  final AccountJson view;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [LanguageButton()],
      title: Text(
        context.tr('Room {0} · Round {1}', [view['code'], view['round']]),
      ),
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 640),
          child: RoundOverview(room: view),
        ),
      ),
    ),
  );
}
