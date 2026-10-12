import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/account_controller.dart';
import 'package:yourname_flutter/game/account_screen.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/game/paper_theme.dart';
import 'package:yourname_flutter/game/player_avatar.dart';
import 'package:yourname_flutter/main.dart';

class TestAccount extends AccountController {
  TestAccount(super.client, {this.authenticated = false}) {
    ready = true;
  }
  bool authenticated;
  @override
  bool get signedIn => authenticated;
  @override
  String? get userId => authenticated ? 'test-user' : null;
  @override
  Future<bool> refresh() async => true;
  @override
  Future<bool> saveProfile(String name, int avatar, String? photo) async {
    profile = {
      'displayName': name,
      'avatarIndex': avatar,
      'avatarImage': photo,
    };
    notifyListeners();
    return true;
  }
}

void main() {
  testWidgets('guests choose any of ten avatars without authentication', (
    tester,
  ) async {
    final client = Client('http://localhost:18080/');
    final account = TestAccount(client);
    final game = GameController(client, account: account)..loading = false;
    await tester.pumpWidget(YournameApp(controller: game));
    await tester.pumpAndSettle();
    expect(find.text('Sign in · optional'), findsOneWidget);
    expect(find.byType(AvatarPicker), findsOneWidget);
    for (var i = 0; i < 10; i++) {
      final option = find.byKey(ValueKey('avatar-$i'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.pump();
      expect(game.avatarIndex, i);
    }
    await tester.enterText(find.byType(TextFormField).first, 'Guest name');
    await tester.ensureVisible(find.text('Sign in · optional'));
    await tester.tap(find.text('Sign in · optional'));
    await tester.pumpAndSettle();
    expect(find.text('The party is open to everyone.'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Guest name'), findsOneWidget);
    expect(game.avatarIndex, 9);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
  for (final signedIn in [false, true]) {
    testWidgets('account fits 320px with large text; signed in $signedIn', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final client = Client('http://localhost:18080/');
      final account = TestAccount(client, authenticated: signedIn)
        ..profile = {'displayName': 'Alice', 'avatarIndex': 3};
      final game = GameController(client, account: account);
      await tester.pumpWidget(
        MaterialApp(
          theme: paperTheme(),
          home: AccountScreen(game: game),
        ),
      );
      await tester.pumpAndSettle();
      if (signedIn) {
        await tester.ensureVisible(find.byKey(const ValueKey('avatar-8')));
        await tester.tap(find.byKey(const ValueKey('avatar-8')));
        await tester.pump();
        await tester.ensureVisible(find.text('Save profile'));
        await tester.tap(find.text('Save profile'));
        await tester.pumpAndSettle();
        expect(account.avatarIndex, 8);
        expect(account.displayName, 'Alice');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets('avatar visual contact sheet', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('NotoSans')
        ..addFont(rootBundle.load('assets/fonts/NotoSans.ttf'));
      await loader.load();
    });
    tester.view.physicalSize = const Size(700, 330);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: paperTheme(),
        home: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 24,
                children: [
                  for (var i = 0; i < 10; i++)
                    SizedBox(
                      width: 110,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlayerAvatar(index: i, size: 88),
                          const SizedBox(height: 8),
                          Text(avatarNames[i]),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('../.local/avatar-contact-sheet.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
