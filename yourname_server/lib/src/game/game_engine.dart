import 'dart:math';

import '../generated/protocol.dart';

typedef Json = Map<String, dynamic>;

/// Pure game rules. Only [view] may cross the server/client boundary.
class GameEngine {
  static int validAvatar(int index) {
    if (index < 0 || index >= 10) fail('Choose one of the 10 avatars.');
    return index;
  }

  static void authorizeAccount(Json player, String? userId) {
    if (player['userId'] != null && player['userId'] != userId) {
      fail('Sign in to the account that owns this seat.');
    }
  }

  static Never fail(String message) => throw GameException(message: message);

  static List<Json> players(Json state) =>
      (state['players'] as List).cast<Json>();

  static String validName(String value) {
    final name = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty ||
        name.runes.length > 24 ||
        name.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      fail('Choose a name between 1 and 24 characters.');
    }
    return name;
  }

  static Json create(
    String id,
    String name,
    String tokenHash,
    int count,
    List<String> categories,
  ) {
    if (count < 2 || count > 30) fail('Choose 2 to 30 questions.');
    if (categories.isEmpty) fail('Choose at least one category.');
    return {
      'phase': 'lobby',
      'hostId': id,
      'version': 1,
      'round': 0,
      'count': count,
      'categories': categories,
      'index': 0,
      'players': <Json>[
        {'id': id, 'name': validName(name), 'tokenHash': tokenHash},
      ],
      'assignments': <String, dynamic>{},
      'questions': <Json>[],
      'answers': <String, dynamic>{},
      'guesses': <String, dynamic>{},
    };
  }

  static void join(Json state, String id, String name, String tokenHash) {
    if (state['phase'] != 'lobby') fail('This game has already started.');
    final members = players(state);
    if (members.length >= 20) fail('This room is full (20 players).');
    final clean = validName(name);
    if (members.any(
      (p) => (p['name'] as String).toLowerCase() == clean.toLowerCase(),
    )) {
      fail('That name is already in the room. Try another.');
    }
    members.add({'id': id, 'name': clean, 'tokenHash': tokenHash});
  }

  static Json authenticate(Json state, String hash) =>
      players(state).firstWhere(
        (p) => p['tokenHash'] == hash,
        orElse: () =>
            fail('Your seat is no longer available. Join a room again.'),
      );

  static void hostOnly(Json state, String id) {
    if (state['hostId'] != id) fail('Only the host can do that.');
  }

  static void start(
    Json state,
    String id,
    List<Json> questions,
    Random random,
  ) {
    hostOnly(state, id);
    if (state['phase'] != 'lobby') fail('The game has already started.');
    final members = players(state);
    if (members.length < 4) fail('At least 4 players are needed to start.');
    if (questions.length < (state['count'] as int)) {
      fail('Not enough questions in these categories. Choose fewer questions.');
    }
    // Rejection sampling is uniform over all derangements, including disjoint
    // cycles. A shuffled circular rotation would unfairly exclude some deals.
    final original = members.map((p) => p['id'] as String).toList();
    final targets = List<String>.from(original);
    do {
      targets.shuffle(random);
    } while (List.generate(
      original.length,
      (i) => original[i] == targets[i],
    ).any((v) => v));
    state['assignments'] = {
      for (var i = 0; i < original.length; i++) original[i]: targets[i],
    };
    questions.shuffle(random);
    state['questions'] = questions.take(state['count'] as int).toList();
    state['phase'] = 'questions';
    state.remove('roundEndedBy');
    state['round'] = (state['round'] as int) + 1;
  }

  static void act(Json state, String id, String action, Json payload) {
    final phase = state['phase'];
    switch (action) {
      case 'answer':
        if (phase != 'questions' ||
            payload['round'] != state['round'] ||
            payload['index'] != state['index']) {
          fail('This question has ended.');
        }
        final choice = payload['choice'];
        if (choice is! int || choice < 0 || choice > 3) {
          fail('Choose A, B, C or D.');
        }
        final answers = state['answers'] as Json;
        final key = '${state['index']}';
        final current =
            answers.putIfAbsent(key, () => <String, dynamic>{}) as Json;
        if (current.containsKey(id)) {
          if (current[id] == choice) return; // Safe retry after lost response.
          fail('Your answer is already locked in.');
        }
        current[id] = choice;
        if (current.length == players(state).length) {
          if ((state['index'] as int) + 1 == state['count']) {
            state['phase'] = 'guessing';
          } else {
            state['index'] = (state['index'] as int) + 1;
          }
        }
      case 'guess':
        if (phase != 'guessing' || payload['round'] != state['round']) {
          fail('It is not time to guess.');
        }
        final target = payload['playerId'];
        if (target == id || !players(state).any((p) => p['id'] == target)) {
          fail('Choose another player in this room.');
        }
        final guesses = state['guesses'] as Json;
        if (guesses.containsKey(id)) {
          if (guesses[id] == target) return;
          fail('Your guess is already locked in.');
        }
        guesses[id] = target;
        if (guesses.length == players(state).length) state['phase'] = 'reveal';
      case 'reset':
        hostOnly(state, id);
        if (phase == 'lobby' || phase == 'closed') {
          fail('There is no round to reset.');
        }
        state['phase'] = 'lobby';
        state.remove('roundEndedBy');
        state['index'] = 0;
        state['assignments'] = <String, dynamic>{};
        state['answers'] = <String, dynamic>{};
        state['guesses'] = <String, dynamic>{};
        state['questions'] = <Json>[];
      case 'leave':
        if (state['hostId'] == id) {
          state['phase'] = 'closed';
          players(state).clear();
          state['assignments'] = <String, dynamic>{};
          state['answers'] = <String, dynamic>{};
          state['guesses'] = <String, dynamic>{};
          state['questions'] = <Json>[];
          state.remove('roundEndedBy');
          break;
        }
        if (phase != 'lobby' && phase != 'closed') {
          state['roundEndedBy'] = players(
            state,
          ).firstWhere((p) => p['id'] == id)['name'];
          state['phase'] = 'lobby';
          state['index'] = 0;
          state['assignments'] = <String, dynamic>{};
          state['answers'] = <String, dynamic>{};
          state['guesses'] = <String, dynamic>{};
          state['questions'] = <Json>[];
        }
        players(state).removeWhere((p) => p['id'] == id);
        if (players(state).isEmpty) {
          state['phase'] = 'closed';
        }
      case 'remove':
        hostOnly(state, id);
        if (phase != 'lobby') {
          fail('Return to the lobby before removing a player.');
        }
        if (payload['playerId'] == id) fail('Use Leave room to leave.');
        players(state).removeWhere((p) => p['id'] == payload['playerId']);
      default:
        fail('Unknown game action.');
    }
  }

  static Json view(Json state, String id, String code) {
    final members = players(state);
    final phase = state['phase'];
    final questions = (state['questions'] as List).cast<Json>();
    final assignments = state['assignments'] as Json;
    final answers = state['answers'] as Json;
    final current = (answers['${state['index']}'] as Json?) ?? {};
    final guesses = state['guesses'] as Json;
    String name(dynamic playerId) =>
        members.firstWhere((p) => p['id'] == playerId)['name'] as String;
    return {
      'code': code, 'phase': phase, 'version': state['version'],
      if (state['roundEndedBy'] != null) 'roundEndedBy': state['roundEndedBy'],
      'round': state['round'], 'selfId': id, 'hostId': state['hostId'],
      'count': state['count'],
      'categories': state['categories'],
      'index': state['index'],
      'players': members
          .map(
            (p) => {
              'id': p['id'],
              'name': p['name'],
              'avatarIndex': p['avatarIndex'] ?? 0,
              'avatarImage': p['avatarImage'],
              'done': phase == 'guessing'
                  ? guesses.containsKey(p['id'])
                  : current.containsKey(p['id']),
            },
          )
          .toList(),
      if (assignments.containsKey(id)) 'assignedName': name(assignments[id]),
      if (phase == 'questions') 'question': questions[state['index'] as int],
      // Only reached questions are sent, with answers as they arrive.
      if (phase == 'questions')
        'questionFeed': [
          for (var i = 0; i <= (state['index'] as int); i++)
            {
              'index': i,
              'prompt': questions[i]['prompt'],
              'category': questions[i]['category'],
              'choices': questions[i]['choices'],
              'myAnswer': (answers['$i'] as Json?)?[id],
              'submissions': [
                for (final author in ((answers['$i'] as Json?) ?? {}).keys)
                  {
                    'playerId': author,
                    'answer':
                        (questions[i]['choices']
                            as List)[(answers['$i'] as Json)[author] as int],
                  },
              ],
            },
        ],
      'myAnswer': current[id], 'answeredCount': current.length,
      'myGuess': guesses[id], 'guessedCount': guesses.length,
      // Legacy completed-round clues are retained only after the reveal.
      if (phase == 'reveal')
        'clues': [
          for (var i = 0; i < questions.length; i++)
            {
              'prompt': questions[i]['prompt'],
              'answer':
                  (questions[i]['choices'] as List)[(answers['$i']
                          as Json)[assignments.entries
                          .firstWhere((e) => e.value == id)
                          .key]
                      as int],
            },
        ],
      if (phase == 'reveal')
        'results': [
          for (final p in members)
            {
              'playerId': p['id'],
              'name': p['name'],
              'actedAs': name(assignments[p['id']]),
              'guessed': name(guesses[p['id']]),
              'actual': name(
                assignments.entries.firstWhere((e) => e.value == p['id']).key,
              ),
              'correct': assignments[guesses[p['id']]] == p['id'],
            },
        ],
      // Browse by author while guessing; identity mappings remain reveal-only.
      if (phase == 'guessing' || phase == 'reveal')
        'answerReview': [
          for (final p in members)
            {
              'playerId': p['id'],
              'name': p['name'],
              if (phase == 'reveal') 'actedAs': name(assignments[p['id']]),
              'answers': [
                for (var i = 0; i < questions.length; i++)
                  {
                    'number': i + 1,
                    'prompt': questions[i]['prompt'],
                    'choice': (answers['$i'] as Json)[p['id']],
                    'answer':
                        (questions[i]['choices']
                            as List)[(answers['$i'] as Json)[p['id']] as int],
                  },
              ],
            },
        ],
    };
  }
}
