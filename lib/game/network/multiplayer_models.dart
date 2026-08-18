import 'package:flutter/foundation.dart';

import '../models/board.dart';
import '../models/tile.dart';

enum MultiplayerPhase { lobby, playing }

class PlayerInfo {
  const PlayerInfo({
    required this.name,
    required this.score,
    required this.tilesLeft,
    this.isSelf = false,
  });

  final String name;
  final int score;
  final int tilesLeft;
  final bool isSelf;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'tilesLeft': tilesLeft,
      };

  factory PlayerInfo.fromJson(Map<String, dynamic> json, {String? selfName}) {
    final name = json['name'] as String;
    return PlayerInfo(
      name: name,
      score: json['score'] as int,
      tilesLeft: json['tilesLeft'] as int,
      isSelf: name == selfName,
    );
  }
}

/// A single player's view of a shared LAN game, as seen on their own device.
class MultiplayerGameState {
  const MultiplayerGameState({
    this.phase = MultiplayerPhase.lobby,
    this.board = const Board(),
    this.availableTiles = const [],
    this.score = 0,
    this.poolCount = 0,
    this.players = const [],
    this.validationError,
  });

  final MultiplayerPhase phase;
  final Board board;
  final List<GameTile> availableTiles;
  final int score;
  final int poolCount;
  final List<PlayerInfo> players;
  final String? validationError;

  bool get isPlaying => phase == MultiplayerPhase.playing;

  bool get canPeel =>
      isPlaying &&
      availableTiles.isEmpty &&
      players.isNotEmpty &&
      poolCount >= players.length;

  MultiplayerGameState copyWith({
    MultiplayerPhase? phase,
    Board? board,
    List<GameTile>? availableTiles,
    int? score,
    int? poolCount,
    List<PlayerInfo>? players,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return MultiplayerGameState(
      phase: phase ?? this.phase,
      board: board ?? this.board,
      availableTiles: availableTiles ?? this.availableTiles, 
      score: score ?? this.score,
      poolCount: poolCount ?? this.poolCount,
      players: players ?? this.players,
      validationError: clearValidationError
          ? null
          : validationError ?? this.validationError,
    );
  }
}

/// Common surface implemented by both the host (playing locally) and remote
/// clients, so the game UI doesn't need to know which one it's talking to.
abstract class MultiplayerController extends ChangeNotifier {
  MultiplayerGameState get multiplayerState;
  void placeTile(String tileId, BoardPosition position);
  void removeTile(BoardPosition position);
  void throwTile(String tileId);
  void peel();
}
