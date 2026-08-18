import '../models/tile.dart';

/// Builds an unshuffled pool of the full Bananagrams tile set.
List<GameTile> createTilePool() {
  const distribution = <String, int>{
    'A': 13,
    'B': 2,
    'C': 2,
    'D': 7,
    'E': 14,
    'F': 3,
    'G': 4,
    'H': 3,
    'I': 8,
    'J': 1,
    'K': 5,
    'L': 8,
    'M': 5,
    'N': 12,
    'O': 6,
    'P': 3,
    'Q': 0,
    'R': 12,
    'S': 9,
    'T': 11,
    'U': 3,
    'V': 3,
    'W': 0,
    'X': 1,
    'Y': 1,
    'Z': 0,
    'Å': 2,
    'Ä': 4,
    'Ö': 2,
  };

  final pool = <GameTile>[];
  var tileNumber = 0;
  for (final entry in distribution.entries) {
    for (var index = 0; index < entry.value; index++) {
      pool.add(GameTile(id: 'tile-${tileNumber++}', letter: entry.key));
    }
  }
  return pool;
}

/// Standard Bananagrams starting hand size for a given number of players.
int startingHandSizeFor(int playerCount) {
  if (playerCount <= 2) return 21;
  if (playerCount <= 4) return 15;
  if (playerCount <= 6) return 11;
  return 9;
}
