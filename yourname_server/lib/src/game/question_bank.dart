import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class QuestionBank {
  static const packs = <String, List<List<String>>>{
    'Everyday': [
      ['What is your favorite color?', 'Red', 'Blue', 'Green', 'Yellow'],
      [
        'How do you like to start your morning?',
        'Coffee first',
        'A workout',
        'A slow breakfast',
        'Five more alarms',
      ],
      [
        'What is your ideal weekend?',
        'Going out',
        'Staying home',
        'Exploring outdoors',
        'Seeing family',
      ],
      [
        'How tidy is your room?',
        'Everything has a place',
        'Mostly tidy',
        'Organized chaos',
        'Please do not look',
      ],
      [
        'When do you have the most energy?',
        'Early morning',
        'After lunch',
        'Evening',
        'After midnight',
      ],
      [
        'What do you usually forget?',
        'Keys',
        'Names',
        'Appointments',
        'Nothing',
      ],
      [
        'What is your shopping style?',
        'Make a list',
        'Compare everything',
        'Follow my mood',
        'Avoid shopping',
      ],
      [
        'Which weather makes you happiest?',
        'Bright sunshine',
        'Gentle rain',
        'Cool breeze',
        'Snow',
      ],
      [
        'How do you get around?',
        'Walk',
        'Public transport',
        'Drive',
        'Ask for a lift',
      ],
      [
        'What do you do with a free hour?',
        'Take a nap',
        'Watch videos',
        'Read something',
        'Message a friend',
      ],
    ],
    'Food & drink': [
      ['Which flavor do you reach for?', 'Sweet', 'Salty', 'Spicy', 'Sour'],
      ['What is your comfort food?', 'Noodles', 'Pizza', 'Soup', 'Rice dishes'],
      ['What is your go-to drink?', 'Coffee', 'Tea', 'Juice', 'Water'],
      [
        'How adventurous are you with food?',
        'Try anything',
        'One bite first',
        'Only familiar things',
        'Let someone else order',
      ],
      [
        'Which dessert wins?',
        'Ice cream',
        'Chocolate cake',
        'Fruit',
        'Cheesecake',
      ],
      [
        'How do you cook?',
        'Follow a recipe',
        'Make it up',
        'Let someone help',
        'Order delivery',
      ],
      [
        'What is your perfect breakfast?',
        'Eggs and toast',
        'Congee or noodles',
        'Pastries',
        'Skip breakfast',
      ],
      ['Which snack disappears first?', 'Chips', 'Cookies', 'Nuts', 'Candy'],
      [
        'How do you choose a restaurant?',
        'Read reviews',
        'Follow friends',
        'Pick the closest',
        'Try somewhere new',
      ],
      [
        'What matters most in a meal?',
        'Taste',
        'Company',
        'Value',
        'Healthy ingredients',
      ],
    ],
    'Personality': [
      [
        'What role do you take in a group?',
        'The planner',
        'The entertainer',
        'The listener',
        'The adventurer',
      ],
      [
        'How do you make a big decision?',
        'Research carefully',
        'Trust my gut',
        'Ask friends',
        'Sleep on it',
      ],
      [
        'What happens when plans change?',
        'Make a new plan',
        'Go with the flow',
        'Get frustrated',
        'Secretly feel relieved',
      ],
      [
        'What kind of gift means most?',
        'Something practical',
        'Something handmade',
        'An experience',
        'A surprise',
      ],
      [
        'How do you react to competition?',
        'Must win',
        'Just have fun',
        'Quietly competitive',
        'Cheer everyone on',
      ],
      [
        'How do you show you care?',
        'Give advice',
        'Spend time together',
        'Help with tasks',
        'Send thoughtful messages',
      ],
      [
        'What is your party style?',
        'Talk to everyone',
        'Stay with close friends',
        'Find the snacks',
        'Leave early',
      ],
      [
        'Which compliment fits you best?',
        'Creative',
        'Reliable',
        'Funny',
        'Kind',
      ],
      [
        'How do you handle a challenge?',
        'Jump straight in',
        'Plan every step',
        'Find a teammate',
        'Take my time',
      ],
      [
        'What do you value most in a friend?',
        'Honesty',
        'Humor',
        'Loyalty',
        'Shared interests',
      ],
    ],
    'Would you rather': [
      [
        'Which superpower would you choose?',
        'Flying',
        'Invisibility',
        'Teleportation',
        'Talking to animals',
      ],
      [
        'Where would you travel next?',
        'A big city',
        'A quiet beach',
        'The mountains',
        'A historic town',
      ],
      [
        'What would you do with a surprise day off?',
        'Sleep in',
        'Take a trip',
        'See friends',
        'Finish a personal project',
      ],
      [
        'Which skill would you instantly master?',
        'Playing music',
        'Speaking languages',
        'Cooking',
        'A sport',
      ],
      [
        'What would your dream home have?',
        'A huge kitchen',
        'A garden',
        'A cinema room',
        'A library',
      ],
      [
        'Which animal would you be for a day?',
        'Cat',
        'Dolphin',
        'Eagle',
        'Dog',
      ],
      [
        'Which adventure would you pick?',
        'Road trip',
        'Camping',
        'Theme park',
        'Food tour',
      ],
      [
        'What would you take to a deserted island?',
        'A good book',
        'A fishing kit',
        'A radio',
        'A friend',
      ],
      [
        'Which fictional world would you visit?',
        'A magical school',
        'A space station',
        'A superhero city',
        'A peaceful fantasy village',
      ],
      [
        'What would you do with a big prize?',
        'Save it',
        'Travel',
        'Help family',
        'Start something new',
      ],
    ],
  };

  /// Stable slugs and a transaction lock make repeated/concurrent seeding safe.
  /// Existing rows are preserved so editors can customize or disable questions.
  static Future<void> seed(Session session) async {
    await session.db.transaction((transaction) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(572019)',
        transaction: transaction,
      );
      for (final pack in packs.entries) {
        for (var i = 0; i < pack.value.length; i++) {
          final slug =
              '${pack.key.toLowerCase().replaceAll(RegExp('[^a-z]+'), '-')}-${i + 1}';
          final exists = await PartyQuestion.db.findFirstRow(
            session,
            where: (t) => t.slug.equals(slug),
            transaction: transaction,
          );
          if (exists != null) continue;
          await PartyQuestion.db.insertRow(
            session,
            PartyQuestion(
              slug: slug,
              category: pack.key,
              prompt: pack.value[i].first,
              choices: pack.value[i].skip(1).toList(),
              enabled: true,
            ),
            transaction: transaction,
          );
        }
      }
    });
  }
}
