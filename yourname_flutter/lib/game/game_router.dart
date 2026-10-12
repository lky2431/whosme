import 'package:flutter/material.dart';
import 'account_screen.dart';
import 'game_controller.dart';
import 'game_screen.dart';
import 'quit_game.dart';

class GameRouteParser extends RouteInformationParser<String> {
  const GameRouteParser();
  @override
  Future<String> parseRouteInformation(
    RouteInformation routeInformation,
  ) async => routeInformation.uri.path;
  @override
  RouteInformation restoreRouteInformation(String configuration) =>
      RouteInformation(uri: Uri(path: configuration));
}

/// The server owns the phase. URLs identify screens, never seat credentials.
class GameRouter extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  GameRouter(this.game) {
    _roomLocation = _location;
    game.addListener(_gameChanged);
  }
  final GameController game;
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _profile = false;
  bool _confirming = false;
  String? _joinCode;
  String? _roomLocation;
  String? get _location =>
      game.room == null ? null : '${game.room!['code']}/${game.room!['phase']}';

  void _gameChanged() {
    final next = _location;
    if (_roomLocation != null && next != _roomLocation) {
      // A remote departure/reset must also dismiss old answer and group sheets.
      navigatorKey.currentState?.popUntil((route) => route is PageRoute);
    }
    _roomLocation = next;
    if (game.room != null || game.hasSeat) _joinCode = null;
    notifyListeners();
  }

  @override
  String get currentConfiguration {
    if (_profile) return '/profile';
    final room = game.room;
    if (room != null) return '/room/${room['code']}/${room['phase']}';
    // Invitation codes prefill this visit only; refreshing home starts fresh.
    return '/';
  }

  void openProfile() {
    _profile = true;
    notifyListeners();
  }

  @override
  Future<void> setInitialRoutePath(String configuration) async {
    _readLink(configuration);
  }

  void _readLink(String path) {
    _profile = path == '/profile' && game.account != null;
    _joinCode = null;
    final parts = Uri.parse(path).pathSegments;
    if (parts.length >= 2 && (parts.first == 'join' || parts.first == 'room')) {
      final code = parts[1].toUpperCase();
      if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) _joinCode = code;
    } else {
      _joinCode = null;
    }
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    if (configuration == '/profile' && game.account != null) {
      openProfile();
      return;
    }
    if (_profile) {
      _profile = false;
    } else if (game.room != null && configuration != currentConfiguration) {
      // Back from a live room asks before changing shared game state.
      if (!_confirming && navigatorKey.currentContext != null) {
        _confirming = true;
        await confirmQuitGame(navigatorKey.currentContext!, game);
        _confirming = false;
      }
      _joinCode = null;
      notifyListeners();
      return;
    }
    _readLink(configuration);
    notifyListeners();
  }

  @override
  Future<bool> popRoute() async {
    if (await navigatorKey.currentState!.maybePop()) return true;
    if (game.room == null) return false;
    if (!_confirming) {
      _confirming = true;
      await confirmQuitGame(navigatorKey.currentContext!, game);
      _confirming = false;
      _joinCode = null;
      notifyListeners();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [
      MaterialPage<void>(
        key: const ValueKey('game'),
        child: GameScreen(
          controller: game,
          initialRoomCode: _joinCode,
          onOpenProfile: openProfile,
        ),
      ),
      if (_profile && game.account != null)
        MaterialPage<void>(
          key: const ValueKey('profile'),
          name: '/profile',
          child: AccountScreen(game: game),
        ),
    ],
    onDidRemovePage: (page) {
      if (page.key == const ValueKey('profile')) {
        _profile = false;
        notifyListeners();
      }
    },
  );

  @override
  void dispose() {
    game.removeListener(_gameChanged);
    super.dispose();
  }
}
