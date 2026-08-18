import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/board.dart';
import '../models/game_state.dart';
import '../rules/game_rules.dart';
import '../rules/word_validator.dart';

class LocalGameController extends ChangeNotifier {
  LocalGameController({GameRules? rules, WordValidator? validator})
      : _rules = rules ?? GameRules(
          validator: validator ?? const WordValidator(words: {}),
        );

  final GameRules _rules;
  GameState _state = const GameState();
  Timer? _timer;

  GameState get state => _state;

  void startGame() {
    _timer?.cancel();
    _state = _rules.startGame();
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _state = _state.copyWith(
        elapsedSeconds: _state.elapsedSeconds + 1,
      );
      notifyListeners();
    });
  }

  void endGame() {
    _timer?.cancel();
    _timer = null;
    _state = const GameState();
    notifyListeners();
  }

  void peel() {
    final nextState = _rules.peel(_state);
    if (identical(nextState, _state)) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  void placeTile(String tileId, BoardPosition position) {
    final nextState = _rules.placeTile(_state, tileId, position);
    if (identical(nextState, _state)) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  void removeTile(BoardPosition position) {
    final nextState = _rules.removeTile(_state, position);
    if (identical(nextState, _state)) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  void throwTile(String tileId) {
    final nextState = _rules.throwTile(_state, tileId);
    if (identical(nextState, _state)) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
