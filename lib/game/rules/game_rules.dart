import 'dart:math';

import '../models/board.dart';
import '../models/game_state.dart';
import 'tile_pool.dart';
import 'word_validator.dart';

class GameRules {
  const GameRules({Random? random, required WordValidator validator})
      : _random = random,
        _validator = validator;

  static const startingTileCount = 21;

  final Random? _random;
  final WordValidator _validator;

  GameState startGame() {
    final pool = createTilePool();
    final random = _random ?? Random();
    pool.shuffle(random);

    return GameState(
      phase: GamePhase.playing,
      availableTiles: pool.take(startingTileCount).toList(),
      remainingTiles: pool.skip(startingTileCount).toList(),
    );
  }

  GameState peel(GameState state) {
    if (!state.canPeel) {
      return state;
    }

    final validation = _validator.validate(state.board);
    if (!validation.isValid) {
      return state.copyWith(
        validationError: 'Invalid words: ${validation.invalidWords.join(', ')}',
      );
    }

    if (state.remainingTiles.isEmpty) {
      return state;
    }

    final nextTile = state.remainingTiles.first;
    return state.copyWith(
      availableTiles: [nextTile],
      remainingTiles: state.remainingTiles.sublist(1),
      clearValidationError: true,
    );
  }

  GameState placeTile(
    GameState state,
    String tileId,
    BoardPosition position,
  ) {
    final tileIndex = state.availableTiles.indexWhere(
      (tile) => tile.id == tileId,
    );
    if (tileIndex == -1 || state.board.isOccupied(position)) {
      return state;
    }

    final tile = state.availableTiles[tileIndex];
    final nextTiles = [...state.availableTiles]..removeAt(tileIndex);
    final nextBoard = state.board.placeTile(position, tile);
    return state.copyWith(
      availableTiles: nextTiles,
      board: nextBoard,
      score: _validator.calculateScore(nextBoard),
      clearValidationError: true,
    );
  }

  GameState removeTile(GameState state, BoardPosition position) {
    final tile = state.board.tiles[position];
    if (tile == null) {
      return state;
    }

    final nextBoard = state.board.removeTile(position);
    return state.copyWith(
      availableTiles: [...state.availableTiles, tile],
      board: nextBoard,
      score: _validator.calculateScore(nextBoard),
      clearValidationError: true,
    );
  }

  GameState throwTile(GameState state, String tileId) {
    final tileIndex = state.availableTiles.indexWhere(
      (tile) => tile.id == tileId,
    );
    if (tileIndex == -1 || state.remainingTiles.isEmpty) {
      return state;
    }

    final thrownTile = state.availableTiles[tileIndex];
    final nextAvailable = [...state.availableTiles]..removeAt(tileIndex);

    final pool = [...state.remainingTiles, thrownTile];
    final random = _random ?? Random();
    pool.shuffle(random);

    final drawCount = min(3, pool.length);
    return state.copyWith(
      availableTiles: [...nextAvailable, ...pool.take(drawCount)],
      remainingTiles: pool.skip(drawCount).toList(),
      clearValidationError: true,
    );
  }
}