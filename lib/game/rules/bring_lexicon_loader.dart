import 'package:flutter/services.dart';

class BringLexiconLoader {
  const BringLexiconLoader();

  static const assetPath = 'bring.txt';

  Future<Set<String>> load() async {
    final contents = await rootBundle.loadString(assetPath);
    final words = <String>{};

    for (final line in contents.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      final columns = trimmed.split('\t');
      if (columns.length < 3) {
        continue;
      }

      final word = columns[2].trim().toLowerCase();
      if (_isPlayableWord(word)) {
        words.add(word);
      }
    }

    return words;
  }

  bool _isPlayableWord(String word) {
    return RegExp(r'^[a-zåäö]+$').hasMatch(word);
  }
}
