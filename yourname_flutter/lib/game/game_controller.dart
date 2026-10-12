import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourname_client/yourname_client.dart';
import 'account_controller.dart';

typedef Json = Map<String, dynamic>;

class GameController extends ChangeNotifier {
  GameController(
    this.client, {
    this.storageKey = 'yourname.seat',
    this.account,
  }) {
    account?.onSignedIn = _linkAccount;
    account?.onSigningOut = forget;
    account?.addListener(_notify);
  }
  final AccountController? account;
  int guestAvatarIndex = 0;
  int get avatarIndex =>
      account?.signedIn == true ? account!.avatarIndex : guestAvatarIndex;
  String? get avatarImage =>
      account?.signedIn == true ? account!.avatarImage : null;
  bool _initializedAccount = false;
  final Client client;
  final String storageKey;
  Map<String, int> categories = {};
  Json? room;
  bool busy = false, connected = false, loading = true;
  String? error, _code, _token;
  StreamSubscription<String>? _subscription;
  Timer? _retry;
  bool _disposed = false;
  int _generation = 0, _attempt = 0;
  bool get hasSeat => _token != null;
  bool get isHost => room != null && room!['hostId'] == room!['selfId'];
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    loading = true;
    _notify();
    try {
      if (!_initializedAccount && account != null) {
        await account!.initialize();
        _initializedAccount = true;
      }
      categories = (jsonDecode(await client.game.categories()) as Json).map(
        (key, value) => MapEntry(key, value as int),
      );
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (saved != null && !hasSeat) {
        final seat = jsonDecode(saved) as Json;
        if (seat['userId'] == null || seat['userId'] == account?.userId) {
          _code = seat['code'] as String;
          _token = seat['token'] as String;
          _watch();
        } else {
          await prefs.remove(storageKey);
        }
      }
      error = null;
    } catch (e) {
      error = _message(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  String _message(Object e) => e is GameException
      ? e.message
      : 'Cannot reach the game server. Check your connection and try again.';
  bool _seatUnavailable(Object e) =>
      e is GameException &&
      const {
        'Room not found or expired. Ask the host for a new code.',
        'Your seat is no longer available. Join a room again.',
        'Your seat is no longer available.',
      }.contains(e.message);

  Future<void> _perform(Future<void> Function() operation) async {
    if (busy) return;
    busy = true;
    error = null;
    _notify();
    try {
      await operation();
    } catch (e) {
      if (hasSeat && _seatUnavailable(e)) {
        await forget();
      } else {
        error = _message(e);
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> create(String name, int count, List<String> selected) =>
      _perform(() async {
        await _accept(
          await client.game.createRoom(
            name,
            count,
            selected,
            avatarIndex: avatarIndex,
          ),
        );
      });
  Future<void> join(String code, String name) => _perform(() async {
    await _accept(
      await client.game.joinRoom(code, name, avatarIndex: avatarIndex),
    );
  });
  Future<void> _accept(String response) async {
    final data = jsonDecode(response) as Json;
    _code = data['code'] as String;
    _token = data['token'] as String;
    room = data['view'] as Json;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode({'code': _code, 'token': _token, 'userId': account?.userId}),
      );
    } catch (_) {
      error = 'Your browser could not save this seat. Keep this page open.';
    }
    _watch();
  }

  Future<void> _linkAccount() async {
    if (_code == null || _token == null) return;
    _receive(await client.game.linkAccount(_code!, _token!));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode({
        'code': _code,
        'token': _token,
        'userId': account?.userId,
      }),
    );
    _watch();
  }

  Future<void> resume(String code) => _perform(() async {
    await _accept(await client.game.resume(code));
  });

  void selectGuestAvatar(int index) {
    guestAvatarIndex = index;
    _notify();
  }

  void _receive(String value) {
    final next = jsonDecode(value) as Json;
    if (room == null || (next['version'] as int) >= (room!['version'] as int)) {
      room = next;
    }
    connected = true;
    if (account?.signedIn != true) {
      final self = (room?['players'] as List?)
          ?.cast<Json>()
          .where((p) => p['id'] == room?['selfId'])
          .firstOrNull;
      guestAvatarIndex = self?['avatarIndex'] as int? ?? guestAvatarIndex;
    }
    _attempt = 0;
    _notify();
  }

  void _watch() {
    if (_disposed || !hasSeat) return;
    final generation = ++_generation;
    _retry?.cancel();
    _subscription?.cancel();
    _subscription = client.game
        .watch(_code!, _token!)
        .listen(
          (value) {
            if (generation != _generation || _disposed) return;
            error = null;
            _receive(value);
          },
          onError: (Object e) {
            if (generation != _generation || _disposed) return;
            if (_seatUnavailable(e)) {
              unawaited(forget());
              return;
            }
            connected = false;
            error = _message(e);
            _notify();
            if (e is! GameException) _scheduleReconnect();
          },
          onDone: () {
            if (generation != _generation || _disposed) return;
            connected = false;
            _notify();
            if (error == null) _scheduleReconnect();
          },
        );
  }

  void _scheduleReconnect() {
    if (_disposed || !hasSeat) return;
    _retry?.cancel();
    _attempt++;
    _retry = Timer(Duration(seconds: _attempt.clamp(1, 10)), _watch);
  }

  void reconnect() {
    error = null;
    _watch();
    _notify();
  }

  Future<void> act(String action, [Json payload = const {}]) =>
      _perform(() async {
        if (_code == null || _token == null) return;
        final data = await client.game.act(
          _code!,
          _token!,
          action,
          jsonEncode(payload),
        );
        if (action == 'leave') {
          await forget();
        } else {
          _receive(data);
        }
      });
  Future<void> forget() async {
    ++_generation;
    _retry?.cancel();
    final subscription = _subscription;
    _subscription = null;
    _code = null;
    _token = null;
    room = null;
    connected = false;
    error = null;
    _notify();
    unawaited(subscription?.cancel());
    try {
      await (await SharedPreferences.getInstance()).remove(storageKey);
    } catch (_) {}
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _retry?.cancel();
    _subscription?.cancel();
    client.close();
    account?.removeListener(_notify);
    account?.dispose();
    super.dispose();
  }
}
