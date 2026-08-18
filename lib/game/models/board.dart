import 'tile.dart';

class BoardPosition {
  const BoardPosition(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) {
    return other is BoardPosition &&
        other.row == row &&
        other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class Board {
  const Board({
    this.tiles = const {},
    this.minRow = 0,
    this.maxRow = 6,
    this.minCol = 0,
    this.maxCol = 6,
  });

  final Map<BoardPosition, GameTile> tiles;
  final int minRow;
  final int maxRow;
  final int minCol;
  final int maxCol;

  int get rowCount => maxRow - minRow + 1;
  int get columnCount => maxCol - minCol + 1;

  bool isOccupied(BoardPosition position) => tiles.containsKey(position);

  // Grows only the side(s) a tile lands near — a single edge grows that one
  // side; a corner grows its row side and column side together.
  Board placeTile(BoardPosition position, GameTile tile) {
    return Board(
      tiles: {...tiles, position: tile},
      minRow: position.row <= minRow + 1 ? minRow - 1 : minRow,
      maxRow: position.row >= maxRow - 1 ? maxRow + 1 : maxRow,
      minCol: position.column <= minCol + 1 ? minCol - 1 : minCol,
      maxCol: position.column >= maxCol - 1 ? maxCol + 1 : maxCol,
    );
  }

  Board removeTile(BoardPosition position) {
    if (!isOccupied(position)) {
      return this;
    }
    return Board(
      tiles: {...tiles}..remove(position),
      minRow: minRow,
      maxRow: maxRow,
      minCol: minCol,
      maxCol: maxCol,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minRow': minRow,
      'maxRow': maxRow,
      'minCol': minCol,
      'maxCol': maxCol,
      'tiles': [
        for (final entry in tiles.entries)
          {
            'row': entry.key.row,
            'col': entry.key.column,
            ...entry.value.toJson(),
          },
      ],
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    final tiles = <BoardPosition, GameTile>{};
    for (final entry in (json['tiles'] as List)) {
      final map = entry as Map<String, dynamic>;
      tiles[BoardPosition(map['row'] as int, map['col'] as int)] =
          GameTile.fromJson(map);
    }
    return Board(
      tiles: tiles,
      minRow: json['minRow'] as int,
      maxRow: json['maxRow'] as int,
      minCol: json['minCol'] as int,
      maxCol: json['maxCol'] as int,
    );
  }
}
