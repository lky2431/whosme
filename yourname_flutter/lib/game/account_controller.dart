import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:yourname_client/yourname_client.dart';
import '../firebase_options.dart';

typedef AccountJson = Map<String, dynamic>;

class AccountController extends ChangeNotifier {
  AccountController(this.client);
  final Client client;
  AccountJson? profile;
  AccountJson games = {'active': <dynamic>[], 'completed': <dynamic>[]};
  bool busy = false, ready = false, _disposed = false;
  bool preparingSignIn = false;
  String? error, message;
  Future<void> Function()? onSignedIn, onSigningOut;
  bool get signedIn => client.auth.isAuthenticated;
  String? get userId => client.auth.authInfo?.authUserId.toString();
  int get avatarIndex => profile?['avatarIndex'] as int? ?? 0;
  String? get avatarImage => profile?['avatarImage'] as String?;
  String get displayName => profile?['displayName'] as String? ?? '';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      await client.auth.initialize();
      if (signedIn) await _load();
    } catch (_) {
      error = 'Your saved account could not be restored. Try signing in again.';
    }
    // Loading the optional Firebase SDK must never hold up guest gameplay.
    unawaited(prepareSignIn());
    _notify();
  }

  Future<void> prepareSignIn() async {
    if (preparingSignIn || ready || _disposed) return;
    preparingSignIn = true;
    error = null;
    _notify();
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: firebaseWebOptions,
        ).timeout(const Duration(seconds: 15));
      } else {
        await Firebase.initializeApp().timeout(const Duration(seconds: 15));
      }
      await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 5),
      );
      ready = true;
    } catch (e, stack) {
      debugPrintStack(
        label: 'Firebase startup failed (${e.runtimeType})',
        stackTrace: stack,
      );
      error =
          'Sign-in is unavailable right now. You can still play as a guest.';
    }
    preparingSignIn = false;
    _notify();
  }

  Future<bool> _perform(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    message = null;
    _notify();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      error = switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Check your email and password, then try again.',
        'email-already-in-use' =>
          'This email already has an account. Sign in instead.',
        'weak-password' =>
          'Choose a stronger password with at least 6 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'popup-closed-by-user' || 'cancelled-popup-request' =>
          'Sign-in was cancelled. You can try again or keep playing as a guest.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'operation-not-allowed' => 'This sign-in method is not enabled yet.',
        'unauthorized-domain' =>
          'Sign-in is not enabled for this website address yet.',
        _ => 'Could not sign in. Check your connection and try again.',
      };
    } on GameException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not reach your account. Please try again.';
    } finally {
      busy = false;
      _notify();
    }
    return false;
  }

  Future<void> _load() async {
    profile = jsonDecode(await client.account.profile()) as AccountJson;
    games = jsonDecode(await client.account.games()) as AccountJson;
  }

  Future<bool> refresh() => _perform(_load);

  Future<void> _finishSignIn() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    if (user.email != null &&
        !FirebaseAuth.instance.currentUser!.emailVerified) {
      throw GameException(
        message:
            'Verify your email first, then sign in. You can resend the verification email below.',
      );
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken(true);
    final result = await client.firebaseIdp.login(idToken: token!);
    await client.auth.updateSignedInUser(result);
    await _load();
    await onSignedIn?.call();
    games = jsonDecode(await client.account.games()) as AccountJson;
  }

  Future<bool> emailSignIn(String email, String password) => _perform(() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _finishSignIn();
  });
  Future<bool> register(String email, String password) => _perform(() async {
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await result.user!.sendEmailVerification();
    message =
        'Check your inbox to verify your email, then sign in. You can play as a guest while you wait.';
  });
  Future<bool> resendVerification() => _perform(() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw GameException(
        message: 'Enter your email and password and try signing in first.',
      );
    }
    await user.sendEmailVerification();
    message = 'Verification email sent. Check your inbox.';
  });
  Future<bool> resetPassword(String email) => _perform(() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    message =
        'If an account exists for this email, you will receive a reset link.';
  });
  Future<bool> googleSignIn() => _perform(() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      await FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider());
    }
    await _finishSignIn();
  });
  Future<bool> saveProfile(String name, int avatar, String? photo) =>
      _perform(() async {
        profile =
            jsonDecode(await client.account.saveProfile(name, avatar, photo))
                as AccountJson;
        await onSignedIn?.call();
        message = 'Profile saved.';
      });
  Future<bool> signOut() => _perform(() async {
    await onSigningOut?.call();
    await client.auth.signOutDevice();
    if (ready) await FirebaseAuth.instance.signOut();
    profile = null;
    games = {'active': <dynamic>[], 'completed': <dynamic>[]};
  });
  Future<AccountJson> history(int id) async =>
      jsonDecode(await client.account.history(id)) as AccountJson;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
