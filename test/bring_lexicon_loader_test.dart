import 'package:flutter_test/flutter_test.dart';

import 'package:bananagrams/game/rules/bring_lexicon_loader.dart';

void main() {
  testWidgets('loads Bring words from the bundled asset', (tester) async {
    final words = await const BringLexiconLoader().load();

    expect(words, isNotEmpty);
    expect(words, contains('existens'));
    expect(words, contains('vara'));
    expect(words.every((word) => word == word.toLowerCase()), isTrue);
  });
}
