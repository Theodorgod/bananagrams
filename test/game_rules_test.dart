import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bananagrams/game/models/board.dart';
import 'package:bananagrams/game/models/tile.dart';
import 'package:bananagrams/game/rules/game_rules.dart';
import 'package:bananagrams/game/rules/word_validator.dart';

void main() {
  final rules = GameRules(
    random: Random(7),
    validator: const WordValidator(words: {'hej', 'hejhej'}),
  );

  test('starts with 21 available tiles', () {
    final state = rules.startGame();

    expect(state.availableTiles, hasLength(21));
    expect(state.remainingTiles, hasLength(123));
    expect(state.isPlaying, isTrue);
    expect(state.canPeel, isFalse);
  });

  test('peel adds one tile only after the rack is empty', () {
    var state = rules.startGame();
    final firstTile = state.availableTiles.first;

    state = state.copyWith(availableTiles: []);
    final peeledState = rules.peel(state);

    expect(peeledState.availableTiles, hasLength(1));
    expect(peeledState.availableTiles.first.id, isNot(firstTile.id));
    expect(
      peeledState.remainingTiles,
      hasLength(state.remainingTiles.length - 1),
    );
  });

  test('cannot place a tile the player does not have', () {
    final state = rules.startGame();
    final nextState = rules.placeTile(
      state,
      'missing-tile',
      const BoardPosition(3, 3),
    );

    expect(nextState, same(state));
  });

  test('placing an available tile moves it onto the board', () {
    final state = rules.startGame();
    final tile = state.availableTiles.first;
    const position = BoardPosition(2, 4);

    final nextState = rules.placeTile(state, tile.id, position);

    expect(nextState.availableTiles, hasLength(20));
    expect(nextState.availableTiles, isNot(contains(tile)));
    expect(nextState.board.tiles[position], same(tile));
  });

  test('peel rejects an invalid horizontal word', () {
    final rules = GameRules(
      random: Random(7),
      validator: const WordValidator(words: {'hej'}),
    );
    var state = rules.startGame();
    final first = GameTile(id: 'first', letter: 'X');
    final second = GameTile(id: 'second', letter: 'Y');
    state = state.copyWith(
      availableTiles: [],
      board: const Board().placeTile(
        BoardPosition(0, 0),
        first,
      ).placeTile(
        BoardPosition(0, 1),
        second,
      ),
    );

    final nextState = rules.peel(state);

    expect(nextState.remainingTiles.length, state.remainingTiles.length);
    expect(nextState.validationError, contains('xy'));
  });

  test('validator reads vertical words', () {
    const validator = WordValidator(words: {'hej'});
    Board board = Board()
        .placeTile(BoardPosition(0, 0), GameTile(id: 'h', letter: 'H'))
        .placeTile(BoardPosition(1, 0), GameTile(id: 'e', letter: 'E'))
        .placeTile(BoardPosition(2, 0), GameTile(id: 'j', letter: 'J'));

    expect(validator.validate(board).isValid, isTrue);
  });
}
