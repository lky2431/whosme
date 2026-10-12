import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:yourname_flutter/game/game_controller.dart';
import 'package:yourname_flutter/l10n/app_language.dart';
import 'package:yourname_flutter/l10n/zh_hant.dart';
import 'package:yourname_flutter/main.dart';
import 'game_screen_test.dart' show fixture;
import 'account_screen_test.dart' show TestAccount;

class HistoryAccount extends TestAccount {
  HistoryAccount(super.client) : super(authenticated: true) {
    profile = {'displayName': 'Blue', 'avatarIndex': 2};
    games = {
      'active': [],
      'completed': [
        {
          'id': 1,
          'code': 'ABC234',
          'round': 1,
          'completedAt': '2026-10-10T00:00:00Z',
        },
      ],
    };
  }
  @override
  Future<Json> history(int id) async => fixture('reveal')
    ..['answerReview'] = [
      {
        'playerId': 'p0',
        'name': 'Blue',
        'actedAs': 'Alice',
        'answers': [
          {
            'number': 1,
            'prompt': 'What is your favorite color?',
            'answer': 'Blue',
          },
        ],
      },
    ];
}

class RecordingGame extends GameController {
  RecordingGame() : super(Client('http://localhost:18080/'));
  Map<String, dynamic>? sent;
  @override
  Future<void> act(String action, [Json data = const {}]) async {
    sent = {'action': action, ...data};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('saved English round renders Chinese answers and switches back', (
    tester,
  ) async {
    final client = Client('http://localhost:18080/');
    final game = GameController(client, account: HistoryAccount(client))
      ..loading = false;
    final language = AppLanguage(locale: supportedLanguages[1]);
    await tester.pumpWidget(YournameApp(controller: game, language: language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('個人檔案與遊戲'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('我的遊戲'));
    await tester.tap(find.text('我的遊戲'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('房間 ABC234・第 1 局'));
    await tester.pumpAndSettle();
    expect(find.text('Blue 扮演的是 Alice'), findsOneWidget);
    expect(find.text('1. 你最喜歡甚麼顏色？'), findsOneWidget);
    expect(find.text('藍色'), findsOneWidget);
    await tester.tap(find.byTooltip('語言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('1. What is your favorite color?'), findsOneWidget);
    expect(find.text('Blue was playing Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    language.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
  test(
    'all seeded questions, ordered choices and categories have translations',
    () {
      final bank = File(
        '../yourname_server/lib/src/game/question_bank.dart',
      ).readAsStringSync().split('/// Stable').first;
      final entries = RegExp(
        "'([^']*)'",
      ).allMatches(bank).skip(2).map((m) => m[1]!).toList();
      expect(entries.length, 204);
      for (final source in entries) {
        expect(traditionalChinese[source], isNotEmpty, reason: source);
        expect(translate(const Locale('en'), source), source);
        expect(translate(supportedLanguages[1], source), isNot(source));
      }
    },
  );
  test(
    'device locale resolution, preference persistence and safe interpolation',
    () async {
      expect(
        AppLanguage.resolve(const Locale('zh', 'HK')),
        supportedLanguages[1],
      );
      expect(AppLanguage.resolve(const Locale('fr')), const Locale('en'));
      final language = AppLanguage(locale: const Locale('en'));
      await language.select(supportedLanguages[1]);
      final restored = AppLanguage();
      await restored.load();
      expect(restored.locale, supportedLanguages[1]);
      expect(
        translate(restored.locale, 'You’re playing {0}', ['Blue {1}']),
        '你正在扮演 Blue {1}',
      );
      expect(translate(restored.locale, 'Custom question'), 'Custom question');
      language.dispose();
      restored.dispose();
    },
  );
  testWidgets(
    'switch language inside a round without changing answers or names',
    (tester) async {
      final game = RecordingGame()
        ..loading = false
        ..connected = true
        ..room = fixture('questions');
      game.room!['assignedName'] = 'Blue';
      final original = jsonEncode(game.room);
      final language = AppLanguage(locale: const Locale('en'));
      await tester.pumpWidget(
        YournameApp(controller: game, language: language),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('繁體中文'));
      await tester.pumpAndSettle();
      expect(find.text('你最喜歡甚麼顏色？'), findsOneWidget);
      expect(find.text('你正在扮演 Blue'), findsOneWidget);
      expect(jsonEncode(game.room), original);
      await tester.tap(find.text('到你了！'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('藍色'));
      await tester.pumpAndSettle();
      await language.select(const Locale('en'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(TextButton, 'Blue'),
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Lock in my answer'));
      await tester.pumpAndSettle();
      expect(game.sent, {
        'action': 'answer',
        'round': 1,
        'index': 0,
        'choice': 1,
      });
      expect(jsonEncode(game.room), original);
      await tester.pumpWidget(const SizedBox());
      game.dispose();
      language.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );
  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final phase in ['home', 'lobby', 'questions', 'guessing', 'reveal']) {
      testWidgets('Traditional Chinese $phase at $size with large text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final game = RecordingGame()
          ..loading = false
          ..connected = true
          ..categories = {'Everyday': 10, 'Food & drink': 10}
          ..room = phase == 'home' ? null : fixture(phase);
        if (phase == 'reveal') {
          game.room!['answerReview'] = [
            {
              'playerId': 'p0',
              'name': 'Blue',
              'actedAs': 'Alice',
              'answers': [
                {
                  'number': 1,
                  'prompt': 'What is your favorite color?',
                  'answer': 'Blue',
                },
              ],
            },
          ];
        }
        final language = AppLanguage(locale: supportedLanguages[1]);
        await tester.pumpWidget(
          YournameApp(controller: game, language: language),
        );
        await tester.pumpAndSettle();
        if (phase == 'questions') {
          await tester.tap(find.text('到你了！'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('藍色'));
          await tester.tap(find.text('藍色'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('確定我的答案'));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        game.dispose();
        language.dispose();
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
  testWidgets('Chinese game visual proof with bundled fonts', (tester) async {
    await tester.runAsync(() async {
      for (final entry in {
        'Nunito': 'assets/fonts/Nunito.ttf',
        'NotoSansTC': 'assets/fonts/NotoSansTC.ttf',
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = RecordingGame()
      ..loading = false
      ..connected = true
      ..room = fixture('questions');
    game.room!['players'][1]['done'] = true;
    final language = AppLanguage(locale: supportedLanguages[1]);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: YournameApp(controller: game, language: language),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('到你了！'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('藍色'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('../.local/chinese-answer.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    language.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
