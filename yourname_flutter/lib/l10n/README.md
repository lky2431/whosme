# English and Traditional Chinese

`AppLanguage` chooses English or Traditional Chinese from the device language on first launch. The globe menu overrides that choice and saves it locally. Each player has an independent preference; switching languages never writes to the room, changes a question, reorders choices, or changes an answer index.

`context.tr(source, arguments)` translates explicit UI messages and the existing question bank through `zh_hant.dart`. Parameters use numbered placeholders such as `{0}`. Pass player names and room codes as parameters, never as translation keys. Parameters are inserted once and are not recursively translated.

All 40 built-in questions, all 160 choice positions, and all four categories have bundled translations. The same content lookup is applied to live questions, the answer sheet, the player's chat bubbles, guessing clues, the final answer review, and saved English-language rounds. Existing stored records require no migration.

This is deterministic, offline translation of supported content, not a call to a machine-translation service. Newly authored or edited content without a catalog entry displays its original text. Add its Traditional Chinese entry before release; `test/localization_test.dart` checks coverage of every seeded question and choice. A future automatic translation service should generate and store translations when content is authored, preserving question identity and choice order rather than generating different wording for each player during a round.

English uses Nunito; Chinese uses bundled Noto Sans TC, including explicit button and app-bar styles. Both font licenses are stored beside the fonts. Flutter's built-in Material localization delegates translate standard control labels and accessibility messages.
