import '../models/board.dart';

class WordValidationResult {
  const WordValidationResult({required this.isValid, this.invalidWords = const []});

  final bool isValid;
  final List<String> invalidWords;
}

class WordValidator {
  const WordValidator({required this.words});

  final Set<String> words;

  WordValidationResult validate(Board board) {
    final boardWords = _readWords(board);
    final invalidWords = boardWords
        .where((word) => !words.contains(word))
        .toList(growable: false);

    return WordValidationResult(
      isValid: invalidWords.isEmpty,
      invalidWords: invalidWords,
    );
  }

  // 1 point for a 2-letter word, +2 points per extra letter (3 -> 3, 4 -> 5, ...).
  int calculateScore(Board board) {
    var score = 0;
    for (final word in _readWords(board)) {
      if (words.contains(word)) {
        score += 2 * word.length - 3;
      }
    }
    return score;
  }

  Set<String> _readWords(Board board) {
    final words = <String>{};
    final positions = board.tiles.keys.toSet();

    for (final position in positions) {
      final horizontal = _readWord(board, position, rowDelta: 0, columnDelta: 1);
      if (horizontal.length > 1) {
        words.add(horizontal);
      }

      final vertical = _readWord(board, position, rowDelta: 1, columnDelta: 0);
      if (vertical.length > 1) {
        words.add(vertical);
      }
    }

    return words;
  }

  String _readWord(
    Board board,
    BoardPosition position, {
    required int rowDelta,
    required int columnDelta,
  }) {
    var start = position;
    while (true) {
      final previous = BoardPosition(
        start.row - rowDelta,
        start.column - columnDelta,
      );
      if (!board.isOccupied(previous)) {
        break;
      }
      start = previous;
    }

    final letters = StringBuffer();
    var current = start;
    while (board.isOccupied(current)) {
      letters.write(board.tiles[current]!.letter.toLowerCase());
      current = BoardPosition(
        current.row + rowDelta,
        current.column + columnDelta,
      );
    }
    return letters.toString();
  }
}
