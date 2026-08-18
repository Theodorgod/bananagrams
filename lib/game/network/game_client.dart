import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/board.dart';
import '../models/tile.dart';
import 'multiplayer_models.dart';

/// Client-side connection to a [GameHostServer] over the local network.
/// The host validates every move; this class only relays actions and
/// reflects back whatever authoritative state the host sends.
class GameClientConnection extends ChangeNotifier implements MultiplayerController {
  Socket? _socket;
  StreamSubscription<String>? _subscription;
  String _name = '';
  MultiplayerGameState _state = const MultiplayerGameState();
  String? _connectionError;

  MultiplayerGameState get state => _state;
  String? get connectionError => _connectionError;

  @override
  MultiplayerGameState get multiplayerState => _state;

  Future<bool> connect(
    String host,
    int port,
    String name, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _name = name;
    try {
      _socket = await Socket.connect(host, port, timeout: timeout);
    } catch (error) {
      _connectionError = 'Could not reach $host:$port';
      notifyListeners();
      return false;
    }

    _socket!.writeln(jsonEncode({'t': 'join', 'name': name}));
    _subscription = utf8.decoder
        .bind(_socket!)
        .transform(const LineSplitter())
        .listen(_handleLine, onDone: _handleDisconnected);
    return true;
  }

  void _handleLine(String line) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (message['t']) {
      case 'error':
        _connectionError = message['message'] as String?;
        notifyListeners();
        break;
      case 'roster':
        _state = _state.copyWith(
          phase: (message['phase'] as String) == 'playing'
              ? MultiplayerPhase.playing
              : MultiplayerPhase.lobby,
          poolCount: message['poolCount'] as int,
          players: [
            for (final entry in (message['players'] as List))
              PlayerInfo.fromJson(entry as Map<String, dynamic>, selfName: _name),
          ],
        );
        notifyListeners();
        break;
      case 'state':
        _state = _state.copyWith(
          phase: (message['phase'] as String) == 'playing'
              ? MultiplayerPhase.playing
              : MultiplayerPhase.lobby,
          board: Board.fromJson(message['board'] as Map<String, dynamic>),
          availableTiles: [
            for (final tile in (message['available'] as List))
              GameTile.fromJson(tile as Map<String, dynamic>),
          ],
          score: message['score'] as int,
          poolCount: message['poolCount'] as int,
          validationError: message['validationError'] as String?,
          clearValidationError: message['validationError'] == null,
        );
        notifyListeners();
        break;
    }
  }

  void _handleDisconnected() {
    _connectionError = 'Lost connection to host';
    notifyListeners();
  }

  @override
  void placeTile(String tileId, BoardPosition position) {
    _send({'t': 'place', 'tileId': tileId, 'row': position.row, 'col': position.column});
  }

  @override
  void removeTile(BoardPosition position) {
    _send({'t': 'remove', 'row': position.row, 'col': position.column});
  }

  @override
  void throwTile(String tileId) {
    _send({'t': 'throw', 'tileId': tileId});
  }

  @override
  void peel() {
    _send({'t': 'peel'});
  }

  void _send(Map<String, dynamic> message) {
    _socket?.writeln(jsonEncode(message));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socket?.close();
    super.dispose();
  }
}
