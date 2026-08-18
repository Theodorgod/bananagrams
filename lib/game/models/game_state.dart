import 'board.dart';
import 'tile.dart';

enum GamePhase { waiting, playing }

class GameState {
  const GameState({
    this.phase = GamePhase.waiting,
    this.elapsedSeconds = 0,
    this.availableTiles = const [],
    this.remainingTiles = const [],
    this.board = const Board(),
    this.score = 0,
    this.validationError,
  });

  final GamePhase phase;
  final int elapsedSeconds;
  final List<GameTile> availableTiles;
  final List<GameTile> remainingTiles;
  final Board board;
  final int score;
  final String? validationError;

  bool get isPlaying => phase == GamePhase.playing;

  bool get canPeel => isPlaying && availableTiles.isEmpty;

  Duration get elapsed => Duration(seconds: elapsedSeconds);

  GameState copyWith({
    GamePhase? phase,
    int? elapsedSeconds,
    List<GameTile>? availableTiles,
    List<GameTile>? remainingTiles,
    Board? board,
    int? score,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      availableTiles: List.unmodifiable(
        availableTiles ?? this.availableTiles,
      ),
      remainingTiles: List.unmodifiable(
        remainingTiles ?? this.remainingTiles,
      ),
      board: board ?? this.board,
      score: score ?? this.score,
      validationError: clearValidationError
          ? null
          : validationError ?? this.validationError,
    );
  }
}
