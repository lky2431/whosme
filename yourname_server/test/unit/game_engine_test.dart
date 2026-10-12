import 'dart:convert';
import 'dart:math';
import 'package:test/test.dart';
import 'package:yourname_server/src/game/game_engine.dart';
import 'package:yourname_server/src/game/question_bank.dart';
import 'package:yourname_server/src/generated/protocol.dart';

Json room({int count = 2, int players = 5}) {
  final state = GameEngine.create('p0', 'Alice', 'hash0', count, ['Everyday']);
  for (var i = 1; i < players; i++) {
    GameEngine.join(state, 'p$i', 'Friend $i', 'hash$i');
  }
  return state;
}

List<Json> questions(int count) => List.generate(
  count,
  (i) => {
    'id': i,
    'prompt': 'Question $i',
    'category': 'Everyday',
    'choices': ['A$i', 'B$i', 'C$i', 'D$i'],
  },
);

void answerRound(Json state) {
  for (var q = 0; q < (state['count'] as int); q++) {
    for (var p = 0; p < GameEngine.players(state).length; p++) {
      GameEngine.act(state, 'p$p', 'answer', {
        'round': state['round'],
        'index': q,
        'choice': p % 4,
      });
    }
  }
}

void main() {
  for (final phase in ['questions', 'guessing', 'reveal']) {
    for (final quitter in ['p1']) {
      test(
        '$quitter leaving $phase ends round and remaining players can restart',
        () {
          final state = room(players: 5);
          GameEngine.start(state, 'p0', questions(2), Random(1));
          if (phase != 'questions') answerRound(state);
          if (phase == 'reveal') {
            for (var p = 0; p < 5; p++) {
              GameEngine.act(state, 'p$p', 'guess', {
                'round': state['round'],
                'playerId': 'p${(p + 1) % 5}',
              });
            }
          }
          GameEngine.act(state, quitter, 'leave', {});
          expect(state['phase'], 'lobby');
          expect(state['hostId'], 'p0');
          expect(GameEngine.players(state).length, 4);
          expect(state['assignments'], isEmpty);
          expect(state['answers'], isEmpty);
          expect(state['guesses'], isEmpty);
          expect(state['questions'], isEmpty);
          expect(
            () => GameEngine.authenticate(state, 'hash${quitter.substring(1)}'),
            throwsA(isA<GameException>()),
          );
          for (final player in GameEngine.players(state)) {
            expect(
              GameEngine.view(state, player['id'], 'ABC234')['phase'],
              'lobby',
            );
          }
          GameEngine.start(state, state['hostId'], questions(2), Random(2));
          expect(state['phase'], 'questions');
          expect(state['round'], 2);
          expect(state.containsKey('roundEndedBy'), isFalse);
        },
      );
    }
  }
  test('quitting a four-player round waits for a replacement in lobby', () {
    final state = room(players: 4);
    GameEngine.start(state, 'p0', questions(2), Random(1));
    GameEngine.act(state, 'p1', 'leave', {});
    expect(
      () => GameEngine.start(state, 'p0', questions(2), Random(2)),
      throwsA(isA<GameException>()),
    );
    GameEngine.join(state, 'new', 'New friend', 'newhash');
    GameEngine.start(state, 'p0', questions(2), Random(2));
    expect(state['phase'], 'questions');
  });
  test(
    'chat shows submitted answers immediately, then complete review after guesses',
    () {
      final state = room(players: 4);
      GameEngine.start(state, 'p0', questions(2), Random(1));
      GameEngine.act(state, 'p1', 'answer', {
        'round': state['round'],
        'index': 0,
        'choice': 2,
      });
      final live = GameEngine.view(state, 'p0', 'ABC234');
      expect(live.containsKey('answerReview'), isFalse);
      expect((live['questionFeed'] as List).length, 1);
      expect(live['questionFeed'][0]['myAnswer'], isNull);
      expect(live['questionFeed'][0]['submissions'], [
        {'playerId': 'p1', 'answer': live['question']['choices'][2]},
      ]);
      for (final p in [0, 2, 3]) {
        GameEngine.act(state, 'p$p', 'answer', {
          'round': state['round'],
          'index': 0,
          'choice': p % 4,
        });
      }
      final next = GameEngine.view(state, 'p0', 'ABC234');
      expect(next['questionFeed'][0]['myAnswer'], 0);
      expect((next['questionFeed'] as List).length, 2);
      for (var p = 0; p < 4; p++) {
        GameEngine.act(state, 'p$p', 'answer', {
          'round': state['round'],
          'index': 1,
          'choice': p % 4,
        });
      }
      expect(
        GameEngine.view(state, 'p0', 'ABC234').containsKey('answerReview'),
        isTrue,
      );
      for (var p = 0; p < 4; p++) {
        GameEngine.act(state, 'p$p', 'guess', {
          'round': state['round'],
          'playerId': 'p${(p + 1) % 4}',
        });
      }
      final review =
          GameEngine.view(state, 'p0', 'ABC234')['answerReview'] as List;
      expect(review.length, 4);
      expect(
        review[1]['answers'][0]['answer'],
        (state['questions'][0]['choices'] as List)[2],
      );
      expect(
        review[1]['answers'][1]['answer'],
        (state['questions'][1]['choices'] as List)[1],
      );
      expect(review[1]['playerId'], 'p1');
    },
  );
  test('four players can finish a round and reset', () {
    final state = room(players: 4);
    GameEngine.start(state, 'p0', questions(2), Random(1));
    answerRound(state);
    expect(state['phase'], 'guessing');
    for (var p = 0; p < 4; p++) {
      GameEngine.act(state, 'p$p', 'guess', {
        'round': state['round'],
        'playerId': 'p${(p + 1) % 4}',
      });
    }
    expect(state['phase'], 'reveal');
    GameEngine.act(state, 'p0', 'reset', {});
    expect(state['phase'], 'lobby');
    expect(GameEngine.players(state).length, 4);
    expect(state['answers'], isEmpty);
    expect(state['guesses'], isEmpty);
  });
  test('cannot start with fewer than four players or as a guest', () {
    expect(
      () => GameEngine.start(room(players: 3), 'p0', questions(2), Random(1)),
      throwsA(isA<GameException>()),
    );
    expect(
      () => GameEngine.start(room(), 'p1', questions(2), Random(1)),
      throwsA(isA<GameException>()),
    );
  });
  test('500 assignments are bijections without self assignments', () {
    for (var seed = 0; seed < 500; seed++) {
      final state = room(players: 4 + seed % 17);
      GameEngine.start(state, 'p0', questions(2), Random(seed));
      final assignments = state['assignments'] as Json;
      expect(assignments.values.toSet().length, assignments.length);
      for (final entry in assignments.entries) {
        expect(entry.key, isNot(entry.value));
      }
    }
  });
  test('names are unique after whitespace and case normalization', () {
    final state = room();
    expect(
      () => GameEngine.join(state, 'new', '  ALICE ', 'token'),
      throwsA(isA<GameException>()),
    );
    expect(
      () => GameEngine.join(state, 'new', '', 'token'),
      throwsA(isA<GameException>()),
    );
    expect(
      () => GameEngine.join(state, 'new', 'a' * 25, 'token'),
      throwsA(isA<GameException>()),
    );
    expect(
      () => GameEngine.join(room(players: 20), 'new', 'Another', 'token'),
      throwsA(isA<GameException>()),
    );
  });
  test('unknown seat credentials fail', () {
    expect(
      () => GameEngine.authenticate(room(), 'wrong'),
      throwsA(isA<GameException>()),
    );
  });
  test(
    'no raw assignments, credentials, future questions or answers are exposed',
    () {
      final state = room();
      GameEngine.start(state, 'p0', questions(2), Random(7));
      final view = GameEngine.view(state, 'p0', 'ABC234');
      for (final key in [
        'assignments',
        'answers',
        'guesses',
        'questions',
        'results',
        'clues',
      ]) {
        expect(view.containsKey(key), false, reason: key);
      }
      expect(jsonEncode(view), isNot(contains('tokenHash')));
      expect(jsonEncode(view), isNot(contains('hash0')));
      expect(
        jsonEncode(view),
        isNot(contains((state['questions'] as List)[1]['prompt'])),
      );
      expect(view['assignedName'], isNot('Alice'));
    },
  );
  test('question waits for all players, validates and locks each answer', () {
    final state = room();
    GameEngine.start(state, 'p0', questions(2), Random(1));
    for (final choice in [-1, 4, 'A']) {
      expect(
        () => GameEngine.act(state, 'p0', 'answer', {
          'round': 1,
          'index': 0,
          'choice': choice,
        }),
        throwsA(isA<GameException>()),
      );
    }
    GameEngine.act(state, 'p0', 'answer', {
      'round': 1,
      'index': 0,
      'choice': 2,
    });
    GameEngine.act(state, 'p0', 'answer', {
      'round': 1,
      'index': 0,
      'choice': 2,
    });
    expect(
      () => GameEngine.act(state, 'p0', 'answer', {
        'round': 1,
        'index': 0,
        'choice': 1,
      }),
      throwsA(isA<GameException>()),
    );
    for (var i = 1; i < 4; i++) {
      GameEngine.act(state, 'p$i', 'answer', {
        'round': 1,
        'index': 0,
        'choice': 0,
      });
    }
    expect(state['index'], 0);
    GameEngine.act(state, 'p4', 'answer', {
      'round': 1,
      'index': 0,
      'choice': 0,
    });
    expect(state['index'], 1);
    expect(
      () => GameEngine.act(state, 'p0', 'answer', {
        'round': 1,
        'index': 0,
        'choice': 2,
      }),
      throwsA(isA<GameException>()),
    );
  });
  test(
    'guessing exposes author answers without identifying the impersonated player',
    () {
      final state = room();
      GameEngine.start(state, 'p0', questions(2), Random(42));
      answerRound(state);
      for (var p = 0; p < 5; p++) {
        final view = GameEngine.view(state, 'p$p', 'ABC234');
        expect(view.containsKey('clues'), isFalse);
        expect(view.containsKey('results'), isFalse);
        expect(view.containsKey('assignments'), isFalse);
        final review = view['answerReview'] as List;
        expect(review, hasLength(5));
        for (var author = 0; author < 5; author++) {
          expect(review[author]['playerId'], 'p$author');
          expect((review[author] as Map).containsKey('actedAs'), isFalse);
          expect(
            review[author]['answers'][0]['answer'],
            state['questions'][0]['choices'][author % 4],
          );
        }
      }
    },
  );
  test(
    'guesses remain private until everyone submits and score inverse assignment',
    () {
      final state = room();
      GameEngine.start(state, 'p0', questions(2), Random(5));
      answerRound(state);
      final assignments = state['assignments'] as Json;
      expect(
        () => GameEngine.act(state, 'p0', 'guess', {
          'round': 1,
          'playerId': 'p0',
        }),
        throwsA(isA<GameException>()),
      );
      for (var p = 0; p < 5; p++) {
        final actor = assignments.entries
            .firstWhere((e) => e.value == 'p$p')
            .key;
        GameEngine.act(state, 'p$p', 'guess', {'round': 1, 'playerId': actor});
        expect(state['phase'], p < 4 ? 'guessing' : 'reveal');
      }
      final view = GameEngine.view(state, 'p0', 'ABC234');
      expect(
        (view['results'] as List).every((r) => r['correct'] == true),
        true,
      );
    },
  );
  test(
    'late joins are rejected, replay preserves roster and rejects stale round',
    () {
      final state = room();
      GameEngine.start(state, 'p0', questions(2), Random(1));
      expect(
        () => GameEngine.join(state, 'new', 'New', 'hash'),
        throwsA(isA<GameException>()),
      );
      expect(
        () => GameEngine.act(state, 'p1', 'reset', {}),
        throwsA(isA<GameException>()),
      );
      GameEngine.act(state, 'p0', 'reset', {});
      expect(GameEngine.players(state).length, 5);
      GameEngine.start(state, 'p0', questions(2), Random(2));
      expect(state['round'], 2);
      expect(
        () => GameEngine.act(state, 'p0', 'answer', {
          'round': 1,
          'index': 0,
          'choice': 0,
        }),
        throwsA(isA<GameException>()),
      );
    },
  );
  for (final phase in ['lobby', 'questions', 'guessing', 'reveal']) {
    test('host leaving $phase destroys room and invalidates every seat', () {
      final state = room(players: 4);
      if (phase != 'lobby') {
        GameEngine.start(state, 'p0', questions(2), Random(1));
        if (phase != 'questions') answerRound(state);
        if (phase == 'reveal') {
          for (var p = 0; p < 4; p++) {
            GameEngine.act(state, 'p$p', 'guess', {
              'round': state['round'],
              'playerId': 'p${(p + 1) % 4}',
            });
          }
        }
      }
      GameEngine.act(state, 'p0', 'leave', {});
      expect(state['phase'], 'closed');
      expect(GameEngine.players(state), isEmpty);
      for (final key in ['assignments', 'answers', 'guesses', 'questions']) {
        expect(state[key], isEmpty);
      }
      for (var p = 0; p < 4; p++) {
        expect(
          () => GameEngine.authenticate(state, 'hash$p'),
          throwsA(isA<GameException>()),
        );
      }
      expect(
        () => GameEngine.join(state, 'new', 'New', 'newhash'),
        throwsA(isA<GameException>()),
      );
      expect(
        () => GameEngine.start(state, 'p0', questions(2), Random(2)),
        throwsA(isA<GameException>()),
      );
    });
  }
  test('all 40 seed questions have four distinct options', () {
    expect(QuestionBank.packs.length, 4);
    for (final pack in QuestionBank.packs.values) {
      expect(pack.length, 10);
      for (final q in pack) {
        expect(q.length, 5);
        expect(q.skip(1).toSet().length, 4);
      }
    }
  });
}
